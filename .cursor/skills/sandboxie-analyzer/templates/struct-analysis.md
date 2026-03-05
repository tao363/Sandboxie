## 结构体名：{{STRUCT_NAME}}

### 基本信息

- **定义位置**：`{{FILE_PATH}}`
- **行号范围**：{{START_LINE}} - {{END_LINE}}
- **大小**：{{SIZE_BYTES}} 字节（{{SIZE_BITS}} 位）
- **对齐**：{{ALIGNMENT}} 字节

---

### 结构体定义

```c
typedef struct {{STRUCT_TAG}} {
    {{FIELD_1_TYPE}} {{FIELD_1_NAME}};    // {{FIELD_1_COMMENT}}
    {{FIELD_2_TYPE}} {{FIELD_2_NAME}};    // {{FIELD_2_COMMENT}}
    // ... 更多字段
} {{STRUCT_NAME}}, *P{{STRUCT_NAME}};
```

---

### 字段说明

| 字段名 | 类型 | 偏移 | 大小 | 说明 |
|--------|------|------|------|------|
| {{FIELD_1_NAME}} | {{FIELD_1_TYPE}} | {{FIELD_1_OFFSET}} | {{FIELD_1_SIZE}} | {{FIELD_1_DESCRIPTION}} |
| {{FIELD_2_NAME}} | {{FIELD_2_TYPE}} | {{FIELD_2_OFFSET}} | {{FIELD_2_SIZE}} | {{FIELD_2_DESCRIPTION}} |

---

### 内存布局

```
偏移 0x00: {{FIELD_1_NAME}} ({{FIELD_1_SIZE}} 字节)
偏移 0x{{FIELD_2_OFFSET}}: {{FIELD_2_NAME}} ({{FIELD_2_SIZE}} 字节)
偏移 0x{{FIELD_3_OFFSET}}: {{FIELD_3_NAME}} ({{FIELD_3_SIZE}} 字节)
...
总大小: {{TOTAL_SIZE}} 字节
```

#### 内存布局图

```
+------------------+
| {{FIELD_1_NAME}}     | 0x00
+------------------+
| {{FIELD_2_NAME}}     | 0x{{FIELD_2_OFFSET}}
+------------------+
| {{FIELD_3_NAME}}     | 0x{{FIELD_3_OFFSET}}
+------------------+
```

---

### 功能描述

{{简要描述结构体的用途和在系统中的角色}}

---

### 生命周期

#### 创建

- **创建位置**：`{{CREATE_FUNCTION}}`
- **创建时机**：{{CREATE_TIMING}}
- **内存分配**：{{MEMORY_ALLOCATION}}

```c
// 创建示例
{{CREATE_CODE_EXAMPLE}}
```

#### 初始化

- **初始化函数**：`{{INIT_FUNCTION}}`
- **初始化步骤**：
  1. {{INIT_STEP_1}}
  2. {{INIT_STEP_2}}

```c
// 初始化示例
{{INIT_CODE_EXAMPLE}}
```

#### 使用

- **主要使用场景**：
  1. {{USE_CASE_1}}
  2. {{USE_CASE_2}}

- **访问方式**：{{ACCESS_METHOD}}

#### 销毁

- **销毁位置**：`{{DESTROY_FUNCTION}}`
- **销毁时机**：{{DESTROY_TIMING}}
- **清理步骤**：
  1. {{CLEANUP_STEP_1}}
  2. {{CLEANUP_STEP_2}}

```c
// 销毁示例
{{DESTROY_CODE_EXAMPLE}}
```

---

### 使用示例

#### 示例 1：{{EXAMPLE_1_TITLE}}

```c
{{EXAMPLE_1_CODE}}
```

#### 示例 2：{{EXAMPLE_2_TITLE}}

```c
{{EXAMPLE_2_CODE}}
```

---

### 关联结构体

#### 包含的结构体

- `{{NESTED_STRUCT_1}}` - {{NESTED_STRUCT_1_DESCRIPTION}}
- `{{NESTED_STRUCT_2}}` - {{NESTED_STRUCT_2_DESCRIPTION}}

#### 被包含于

- `{{PARENT_STRUCT_1}}` - {{PARENT_STRUCT_1_DESCRIPTION}}
- `{{PARENT_STRUCT_2}}` - {{PARENT_STRUCT_2_DESCRIPTION}}

#### 关联图

```mermaid
classDiagram
    class {{STRUCT_NAME}} {
        +{{FIELD_1_TYPE}} {{FIELD_1_NAME}}
        +{{FIELD_2_TYPE}} {{FIELD_2_NAME}}
    }
    
    class {{RELATED_STRUCT_1}} {
        +...
    }
    
    {{STRUCT_NAME}} --> {{RELATED_STRUCT_1}} : uses
```

---

### 访问函数

#### 创建/初始化

- `{{CREATE_FUNCTION}}` - {{CREATE_FUNCTION_DESCRIPTION}}
- `{{INIT_FUNCTION}}` - {{INIT_FUNCTION_DESCRIPTION}}

#### 访问/修改

- `{{GETTER_FUNCTION_1}}` - {{GETTER_FUNCTION_1_DESCRIPTION}}
- `{{SETTER_FUNCTION_1}}` - {{SETTER_FUNCTION_1_DESCRIPTION}}

#### 销毁/清理

- `{{DESTROY_FUNCTION}}` - {{DESTROY_FUNCTION_DESCRIPTION}}
- `{{CLEANUP_FUNCTION}}` - {{CLEANUP_FUNCTION_DESCRIPTION}}

---

### 设计考虑

#### 设计原则

1. **{{DESIGN_PRINCIPLE_1}}**：{{DESIGN_PRINCIPLE_1_DESCRIPTION}}
2. **{{DESIGN_PRINCIPLE_2}}**：{{DESIGN_PRINCIPLE_2_DESCRIPTION}}

#### 为什么这样设计

{{DESIGN_RATIONALE}}

#### 优势

- ✅ {{ADVANTAGE_1}}
- ✅ {{ADVANTAGE_2}}

#### 劣势/限制

- ⚠️ {{LIMITATION_1}}
- ⚠️ {{LIMITATION_2}}

---

### 线程安全性

- **是否线程安全**：{{THREAD_SAFE_YES_NO}}
- **保护机制**：{{PROTECTION_MECHANISM}}
- **锁的使用**：{{LOCK_USAGE}}
- **注意事项**：{{THREAD_SAFETY_NOTES}}

---

### 性能考虑

- **内存占用**：{{MEMORY_FOOTPRINT}}
- **缓存友好性**：{{CACHE_FRIENDLINESS}}
- **对齐优化**：{{ALIGNMENT_OPTIMIZATION}}
- **性能影响**：{{PERFORMANCE_IMPACT}}

---

### 安全考虑

- **敏感数据**：{{SENSITIVE_DATA}}
- **访问控制**：{{ACCESS_CONTROL}}
- **潜在风险**：{{SECURITY_RISK}}
- **缓解措施**：{{MITIGATION}}

---

### 版本兼容性

#### 不同版本的变化

| 版本 | 变化 | 影响 |
|------|------|------|
| {{VERSION_1}} | {{CHANGE_1}} | {{IMPACT_1}} |
| {{VERSION_2}} | {{CHANGE_2}} | {{IMPACT_2}} |

#### 向后兼容性

{{BACKWARD_COMPATIBILITY}}

---

### 调试技巧

#### 常见问题

1. **{{COMMON_ISSUE_1}}**：{{COMMON_ISSUE_1_SOLUTION}}
2. **{{COMMON_ISSUE_2}}**：{{COMMON_ISSUE_2_SOLUTION}}

#### 调试命令

```
// WinDbg 命令
dt {{STRUCT_NAME}} {{ADDRESS}}
dt -r {{STRUCT_NAME}} {{ADDRESS}}  // 递归显示

// 显示特定字段
dt {{STRUCT_NAME}} {{FIELD_NAME}} {{ADDRESS}}
```

---

### 相关宏定义

```c
#define {{MACRO_1}} {{MACRO_1_VALUE}}  // {{MACRO_1_DESCRIPTION}}
#define {{MACRO_2}} {{MACRO_2_VALUE}}  // {{MACRO_2_DESCRIPTION}}
```

---

### 使用统计

- **使用频率**：{{USAGE_FREQUENCY}}
- **实例数量**：{{INSTANCE_COUNT}}
- **主要使用者**：{{MAIN_USERS}}

---

### 测试建议

#### 单元测试

```c
// 测试用例 1：{{TEST_CASE_1}}
{{TEST_CODE_1}}

// 测试用例 2：{{TEST_CASE_2}}
{{TEST_CODE_2}}
```

#### 边界条件

- {{BOUNDARY_CONDITION_1}}
- {{BOUNDARY_CONDITION_2}}

---

### 参考资料

- [相关文档 1]({{REFERENCE_1_LINK}})
- [相关文档 2]({{REFERENCE_2_LINK}})
- [Windows 文档]({{WINDOWS_DOC_LINK}})

---

### TODO / FIXME

- [ ] {{TODO_1}}
- [ ] {{TODO_2}}

---

**分析日期**：{{ANALYSIS_DATE}}  
**分析者**：{{ANALYZER}}
