/*
 * Direct IP Access Protection Implementation
 * 
 * 防止直接 IP 访问的完整实现
 * 包括：DNS 缓存关联、IP 检查、SNI 验证
 */

#ifndef _MY_DOMAIN_FILTER_IP_H
#define _MY_DOMAIN_FILTER_IP_H

#include "common/map.h"
#include "common/list.h"

// IP 检查结果
typedef enum _IP_CHECK_RESULT {
    IP_CHECK_ALLOWED = 0,           // IP 被允许
    IP_CHECK_BLOCKED = 1,           // IP 被拒绝
    IP_CHECK_UNKNOWN = 2,           // IP 未知（需要进一步检查）
} IP_CHECK_RESULT;

// IP 来源类型
typedef enum _IP_SOURCE_TYPE {
    IP_SOURCE_DNS_CACHE = 0,        // 来自 DNS 缓存
    IP_SOURCE_WHITELIST = 1,        // 来自 IP 白名单
    IP_SOURCE_LOCAL = 2,            // 本地 IP
    IP_SOURCE_UNKNOWN = 3,          // 未知来源
} IP_SOURCE_TYPE;

// 扩展的 DNS 缓存条目
typedef struct _DNS_CACHE_ENTRY_EX {
    WCHAR* domain;                  // 域名
    IP_ADDRESS ip;                  // 解析的 IP
    DWORD ttl;                      // TTL（秒）
    DWORD timestamp;                // 缓存时间戳
    ULONG access_count;             // 访问次数
    BOOLEAN verified;               // 是否已验证（防欺骗）
    IP_SOURCE_TYPE source_type;     // IP 来源类型
    LIST_ELEM list_elem;
} DNS_CACHE_ENTRY_EX;

// IP 检查结果详情
typedef struct _IP_CHECK_INFO {
    IP_CHECK_RESULT result;         // 检查结果
    IP_SOURCE_TYPE source_type;     // IP 来源
    WCHAR domain[256];              // 关联的域名
    DWORD ttl_remaining;            // 剩余 TTL
    BOOLEAN is_local;               // 是否为本地 IP
} IP_CHECK_INFO;

// 扩展的域名过滤状态
typedef struct _DOMAIN_FILTER_STATE_EX {
    HASH_MAP domain_rules;          // 域名规则
    HASH_MAP dns_cache;             // DNS 缓存（按域名索引）
    HASH_MAP ip_cache;              // IP 缓存（按 IP 索引）
    HASH_MAP ip_whitelist;          // IP 白名单
    KSPIN_LOCK lock;
    BOOLEAN enabled;
    BOOLEAN block_direct_ip;        // 是否阻止直接 IP 访问
    BOOLEAN enable_sni_check;       // 是否启用 SNI 检查
    ULONG dns_cache_ttl;
} DOMAIN_FILTER_STATE_EX;

// ============================================================================
// IP 检查函数
// ============================================================================

// 检查 IP 是否被允许（返回详细信息）
NTSTATUS DomainFilter_CheckIPEx(
    const IP_ADDRESS* ip,
    IP_CHECK_INFO* pCheckInfo);

// 检查 IP 是否被允许（简化版）
BOOLEAN DomainFilter_CheckIP(
    const IP_ADDRESS* ip,
    WCHAR* domain,
    SIZE_T domain_len);

// 检查是否为本地 IP
BOOLEAN DomainFilter_IsLocalIP(const IP_ADDRESS* ip);

// 检查是否为私有 IP（RFC 1918）
BOOLEAN DomainFilter_IsPrivateIP(const IP_ADDRESS* ip);

// ============================================================================
// IP 白名单管理
// ============================================================================

// 添加 IP 到白名单
NTSTATUS DomainFilter_AddIPWhitelist(const IP_ADDRESS* ip);

// 移除 IP 白名单
NTSTATUS DomainFilter_RemoveIPWhitelist(const IP_ADDRESS* ip);

// 检查 IP 是否在白名单中
BOOLEAN DomainFilter_IsIPWhitelisted(const IP_ADDRESS* ip);

// ============================================================================
// DNS 缓存管理（扩展）
// ============================================================================

// 缓存 DNS 查询结果（带来源类型）
NTSTATUS DomainFilter_CacheDNSEx(
    const WCHAR* domain,
    const IP_ADDRESS* ip,
    DWORD ttl,
    IP_SOURCE_TYPE source_type);

// 清理过期的 DNS 缓存
NTSTATUS DomainFilter_CleanupExpiredCache(void);

// 获取 DNS 缓存统计
NTSTATUS DomainFilter_GetCacheStats(
    ULONG* pDomainCacheCount,
    ULONG* pIPCacheCount);

// ============================================================================
// 日志记录
// ============================================================================

// 记录 IP 访问日志
void DomainFilter_LogIPAccess(
    const WCHAR* domain,
    const IP_ADDRESS* ip,
    ULONG port,
    BOOLEAN allowed,
    const WCHAR* reason);

#endif // _MY_DOMAIN_FILTER_IP_H
