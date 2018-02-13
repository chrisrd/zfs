dnl #
dnl # 4.8 API change
dnl # kernel vm counters change
dnl #
AC_DEFUN([ZFS_AC_KERNEL_GLOBAL_NODE_PAGE_STATE], [
	AC_MSG_CHECKING([whether global_node_page_state() exists])
	ZFS_LINUX_TRY_COMPILE([
		#include <linux/mm.h>
		#include <linux/vmstat.h>
	],[
		(void) global_node_page_state(0);
	],[
		AC_MSG_RESULT(yes)
		AC_DEFINE(ZFS_GLOBAL_NODE_PAGE_STATE, 1, [global_node_page_state() exists])
	],[
		AC_MSG_RESULT(no)
	])
])

dnl #
dnl # 4.14 API change (c41f012ade)
dnl # mm: rename global_page_state to global_zone_page_state
dnl #
AC_DEFUN([ZFS_AC_KERNEL_GLOBAL_ZONE_PAGE_STATE], [
	AC_MSG_CHECKING([whether global_zone_page_state() exists])
	ZFS_LINUX_TRY_COMPILE([
		#include <linux/mm.h>
		#include <linux/vmstat.h>
	],[
		(void) global_zone_page_state(0);
	],[
		AC_MSG_RESULT(yes)
		AC_DEFINE(ZFS_GLOBAL_ZONE_PAGE_STATE, 1, [global_zone_page_state() exists])
	],[
		AC_MSG_RESULT(no)
	])
])

dnl #
dnl # Create a define for an enum member
dnl #
AC_DEFUN([ZFS_AC_KERNEL_ENUM_MEMBER], [
	AC_MSG_CHECKING([whether enum $2 contains $1])
	AS_IF([AC_TRY_COMMAND("${srcdir}/scripts/enum-extract.pl" "$2" "$3" | egrep -qx $1)],[
		AC_MSG_RESULT([yes])
		AC_DEFINE(m4_join([_], [ZFS_ENUM], m4_toupper($2), $1), 1, [enum $2 contains $1])
	],[
		AC_MSG_RESULT([no])
	])
])

dnl #
dnl # Sanity check our global_page_state enums
dnl #
AC_DEFUN([ZFS_AC_KERNEL_GLOBAL_ZONE_PAGE_STATE_SANITY], [
	AC_MSG_CHECKING([global_page_state enums are sane])
	ZFS_LINUX_TRY_COMPILE([
		#include <linux/mm.h>
		#include <linux/vmstat.h>
	],[
		/*
		 * Ensure the config tests are finding one and only one of each enum of interest
		 */
		#if	defined(ZFS_ENUM_NODE_STAT_ITEM_NR_FILE_PAGES) && \
			defined(ZFS_ENUM_ZONE_STAT_ITEM_NR_FILE_PAGES)
		#error NR_FILE_PAGES found in both node_stat_item and zone_stat_item
		#elif	! defined(ZFS_ENUM_NODE_STAT_ITEM_NR_FILE_PAGES) && \
			! defined(ZFS_ENUM_ZONE_STAT_ITEM_NR_FILE_PAGES)
		#error NR_FILE_PAGES not found in either node_stat_item or zone_stat_item
		#endif

		#if	defined(ZFS_ENUM_NODE_STAT_ITEM_NR_INACTIVE_ANON) && \
			defined(ZFS_ENUM_ZONE_STAT_ITEM_NR_INACTIVE_ANON)
		#error NR_INACTIVE_ANON found in both node_stat_item and zone_stat_item
		#elif	! defined(ZFS_ENUM_NODE_STAT_ITEM_NR_INACTIVE_ANON) && \
			! defined(ZFS_ENUM_ZONE_STAT_ITEM_NR_INACTIVE_ANON)
		#error NR_INACTIVE_ANON not found in either node_stat_item or zone_stat_item
		#endif

		#if	defined(ZFS_ENUM_NODE_STAT_ITEM_NR_INACTIVE_FILE) && \
			defined(ZFS_ENUM_ZONE_STAT_ITEM_NR_INACTIVE_FILE)
		#error NR_INACTIVE_FILE found in both node_stat_item and zone_stat_item
		#elif	! defined(ZFS_ENUM_NODE_STAT_ITEM_NR_INACTIVE_FILE) && \
			! defined(ZFS_ENUM_ZONE_STAT_ITEM_NR_INACTIVE_FILE)
		#error NR_INACTIVE_FILE not found in either node_stat_item or zone_stat_item
		#endif

		#if	defined(ZFS_ENUM_NODE_STAT_ITEM_NR_SLAB_RECLAIMABLE) && \
			defined(ZFS_ENUM_ZONE_STAT_ITEM_NR_SLAB_RECLAIMABLE)
		#error NR_SLAB_RECLAIMABLE found in both node_stat_item and zone_stat_item
		#elif	! defined(ZFS_ENUM_NODE_STAT_ITEM_NR_SLAB_RECLAIMABLE) && \
			! defined(ZFS_ENUM_ZONE_STAT_ITEM_NR_SLAB_RECLAIMABLE)
		#error NR_SLAB_RECLAIMABLE not found in either node_stat_item or zone_stat_item
		#endif
	],[
		AC_MSG_RESULT(yes)
	],[
		AC_MSG_RESULT(no)
		AC_MSG_RESULT([configure needs updating, see: config/kernel-global_page_state.m4])
		AC_MSG_FAILURE([SHUT 'ER DOWN CLANCY, SHE'S PUMPIN' MUD!])
	])
])


dnl #
dnl # enum members in which we're interested
dnl #
AC_DEFUN([ZFS_AC_KERNEL_GLOBAL_PAGE_STATE], [
	ZFS_AC_KERNEL_GLOBAL_NODE_PAGE_STATE
	ZFS_AC_KERNEL_GLOBAL_ZONE_PAGE_STATE

	ZFS_AC_KERNEL_ENUM_MEMBER([NR_FILE_PAGES],		[node_stat_item], [$LINUX/include/linux/mmzone.h])
	ZFS_AC_KERNEL_ENUM_MEMBER([NR_INACTIVE_ANON],		[node_stat_item], [$LINUX/include/linux/mmzone.h])
	ZFS_AC_KERNEL_ENUM_MEMBER([NR_INACTIVE_FILE],		[node_stat_item], [$LINUX/include/linux/mmzone.h])
	ZFS_AC_KERNEL_ENUM_MEMBER([NR_SLAB_RECLAIMABLE],	[node_stat_item], [$LINUX/include/linux/mmzone.h])

	ZFS_AC_KERNEL_ENUM_MEMBER([NR_FILE_PAGES],		[zone_stat_item], [$LINUX/include/linux/mmzone.h])
	ZFS_AC_KERNEL_ENUM_MEMBER([NR_INACTIVE_ANON],		[zone_stat_item], [$LINUX/include/linux/mmzone.h])
	ZFS_AC_KERNEL_ENUM_MEMBER([NR_INACTIVE_FILE],		[zone_stat_item], [$LINUX/include/linux/mmzone.h])
	ZFS_AC_KERNEL_ENUM_MEMBER([NR_SLAB_RECLAIMABLE],	[zone_stat_item], [$LINUX/include/linux/mmzone.h])

	ZFS_AC_KERNEL_GLOBAL_ZONE_PAGE_STATE_SANITY
])
