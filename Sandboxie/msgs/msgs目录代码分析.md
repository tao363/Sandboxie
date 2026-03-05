# Sandboxie msgs 目录代码分析

## 目录概述

`Sandboxie\msgs` 目录是 Sandboxie 项目的**多语言消息资源管理系统**。该目录负责管理 Sandboxie 所有用户界面文本、错误消息、事件日志和弹出提示的国际化（i18n）支持。

## 目录结构

```
msgs/
├── parse.c                      # 消息解析器源代码（核心工具）
├── Parse.vcxproj                # 解析器项目文件
├── SboxMsg.vcxproj              # 消息 DLL 项目文件
├── msgs.h                       # 消息头文件
├── resource.rc                  # 资源文件
├── sbiemsg.def                  # DLL 导出定义文件
├── RunReport.bat                # 批处理：生成翻译报告
├── SbieText.bat                 # 批处理：打包文本文件
├── Sbie-English-1033.txt        # 英文主消息文件
├── Text-{Language}-{LCID}.txt   # 各语言翻译文件（32个语言）
└── report/                      # 翻译报告目录
    └── Report-{Language}.txt    # 各语言的缺失消息报告
```

---

## 核心文件详细分析

### 1. parse.c - 消息解析器（核心工具程序）

**文件作用**：这是整个消息系统的核心工具，负责解析所有语言的文本文件并生成 Windows 消息资源。

#### 主要数据结构

```c
struct MSG {
    LIST_ELEM list_elem;
    ULONG code;      // 消息代码（包含设施码、严重性等）
    ULONG ver;       // 消息版本号
    WCHAR *text;     // 消息文本内容
};

struct LANG {
    LIST_ELEM list_elem;
    WCHAR name[128]; // 语言名称（如 "French"）
    ULONG code;      // LCID 语言代码（如 1036）
    LIST msgs;       // 该语言的所有消息列表
};
```

#### 核心函数分析

##### 1.1 `Alloc(ULONG Size)`
**功能**：内存分配包装函数
- 使用 `HeapAlloc` 分配内存
- 验证分配成功，失败则退出程序
- 确保堆的完整性

##### 1.2 `AddTextEntry(const UCHAR *path, WCHAR *BufPtr, LIST *msgs, ULONG LineNum)`
**功能**：解析单个消息条目并添加到消息列表

**消息格式解析**：
```
NNNN;[设施类型];[严重性];VV
消息文本内容
.
```

**设施类型（Facility）**：
- `evt` - 事件日志消息（Facility=0x101）
- `pop` - 弹出窗口消息（Facility=0x102）
- `evt;pop` - 同时记录到事件和弹出（Facility=0x103）
- `txt` - 纯文本消息（Facility=0x000）
- `ins` - NSIS 安装程序文本（Facility=0xFFF）

**严重性级别（Severity）**：
- `inf` - 信息（Informational, 1 << 30）
- `wrn` - 警告（Warning, 2 << 30）
- `err` - 错误（Error, 3 << 30）

**示例**：
```
1101;evt;inf;01
SBIE1101 Sandboxie driver (SbieDrv) version %2 initialized
.
```
解析为：
- 代码：1101
- 设施：事件日志
- 严重性：信息
- 版本：01
- 文本：驱动初始化消息

##### 1.3 `ReadTextFile(const UCHAR *path, LIST *msgs)`
**功能**：读取并解析整个文本文件

**处理流程**：
1. 打开文件并读取全部内容
2. 检测文件编码（支持 UTF-16 LE BOM 和 UTF-8 BOM）
3. 如果是 UTF-8，转换为 Unicode
4. 逐行解析，跳过注释行（以 `#` 开头）
5. 调用 `AddTextEntry` 处理每个消息条目
6. 验证 CRLF 格式正确性

##### 1.4 `DiscardOldText(const UCHAR *Name, LIST *msgs)`
**功能**：版本管理 - 保留每个消息代码的最新版本

**逻辑**：
- 遍历所有消息，查找相同代码的消息
- 如果版本号相同，报错退出（不允许重复）
- 如果找到更高版本，更新消息内容
- 删除旧版本消息

##### 1.5 `FindTextEntry(LIST *msgs, ULONG code, ULONG ver)`
**功能**：在消息列表中查找指定代码和版本的消息

##### 1.6 `CompareText(UCHAR *Name, LIST *Foreign, LIST *English)`
**功能**：比较外语翻译与英文原文，生成翻译报告

**检查内容**：
1. **缺失的消息**：英文中有但外语中没有的消息
   - 自动将英文文本添加到外语列表（作为占位符）
2. **多余的消息**：外语中有但英文中没有的消息
   - 报告这些多余的条目

##### 1.7 `AddLanguage(LIST *langs, LIST *msgs, const UCHAR *filename)`
**功能**：将语言添加到语言列表

**解析文件名**：
- 格式：`Text-{LanguageName}-{LCID}.txt`
- 提取语言名称和 LCID 代码
- 示例：`Text-French-1036.txt` → 名称="French", 代码=1036

##### 1.8 `WriteMessageFile(LIST *langs)`
**功能**：生成 Windows 消息编译器（mc.exe）的输入文件 `msgs.mc`

**生成内容**：
1. **FacilityNames** 定义：
```
FacilityNames=(
    Text=0
    Event=0x101:MSG_FACILITY_EVENT
    Popup=0x102:MSG_FACILITY_POPUP
    EventPopup=0x103
)
```

2. **LanguageNames** 定义：
```
LanguageNames=(
    French=0x40C:MSG0040C
    German=0x407:MSG00407
    ...
)
```

3. **消息定义**：
```
MessageId=1101 Facility=Event Severity=Informational SymbolicName=MSG_1101
Language=English
SBIE1101 Sandboxie driver (SbieDrv) version %2 initialized
.
Language=French
SBIE1101 Pilote Sandboxie (SbieDrv) version %2 initialisé
.
```

##### 1.9 `FindCopyTextForNsis(struct MSG *mf, LIST *msgs)`
**功能**：处理 NSIS 文本的复制引用

**特殊语法**：
- 如果文本以 `=copy:NNNN` 开头，从指定代码的消息复制文本
- 自动删除末尾的句点（NSIS 格式要求）

##### 1.10 `WriteNsisFiles(LIST *langs)`
**功能**：为 NSIS 安装程序生成语言字符串文件

**输出格式**：
```
LangString MSG_2101 ${LANG_FRENCH} "文本内容$\n换行"
```

**特点**：
- 文件保存为 UTF-16 LE（BOM: 0xFEFF）
- 将 `\r\n` 转换为 NSIS 的 `$\n` 格式
- 只处理 Facility=0xFFF 的消息

##### 1.11 `main(int argc, char *argv[])`
**功能**：主程序入口

**执行流程**：
1. 读取英文主文件 `Text-English-1033.txt`
2. 丢弃旧版本消息
3. 将英文添加为第一个语言
4. 遍历命令行参数中的所有外语文件
5. 对每个外语文件：
   - 读取并解析
   - 丢弃旧版本
   - 与英文比较，生成报告
   - 添加到语言列表
6. 生成 `msgs.mc` 文件（Windows 消息编译器输入）
7. 生成 NSIS 语言文件

---

### 2. msgs.h - 消息头文件

**文件作用**：简单的头文件包装器

```c
#ifndef _MY_MSGS_H
#define _MY_MSGS_H

#include "msgs\SbieRelease\msgs.h"

#endif // _MY_MSGS_H
```

**说明**：
- 包含构建生成的 `msgs.h`（由 mc.exe 从 msgs.mc 生成）
- 该生成的头文件包含所有消息的符号常量定义

---

### 3. resource.rc - 资源脚本

**文件作用**：定义 SbieMsg.dll 的资源和版本信息

**主要内容**：
1. 包含生成的消息资源：`#include "msgs\SbieRelease\msgs.rc"`
2. 版本信息块（VS_VERSION_INFO）
   - 文件版本和产品版本
   - 公司名称、产品名称
   - 版权信息
   - 文件描述："Sandboxie Messages and Text"

---

### 4. sbiemsg.def - DLL 定义文件

**文件作用**：定义 DLL 的导出信息

```
LIBRARY SbieMsg
```

**说明**：
- 指定 DLL 名称为 SbieMsg
- 这是一个纯资源 DLL（无导出函数）

---

### 5. RunReport.bat - 翻译报告生成脚本

**文件作用**：批量生成所有语言的翻译报告

```batch
for %%a in (Text-*-*.txt) do call :MySub %%a
exit /b
:MySub
if %1 == Text-English-1033.txt goto :MySubEnd
for /f "delims=- tokens=2" %%b in ("%1") do set MySubLang=%%b
parse Text-English-1033.txt %1 > report\Report-%MySubLang%.txt 2>&1
:MySubEnd
exit /b
```

**执行流程**：
1. 遍历所有 `Text-*.txt` 文件
2. 跳过英文文件
3. 提取语言名称（从文件名）
4. 运行 parse.exe 比较英文和该语言
5. 将输出重定向到 `report\Report-{Language}.txt`

---

### 6. SbieText.bat - 文本打包脚本

**文件作用**：打包所有文本文件和报告

```batch
7za a -tzip SbieText.zip *.txt report\*.txt parse.exe
move /y SbieText.zip C:\
```

**功能**：
- 使用 7-Zip 压缩所有 .txt 文件
- 包含 report 目录中的报告
- 包含 parse.exe 工具
- 移动到 C:\ 根目录

---

### 7. Parse.vcxproj - 解析器项目文件

**文件作用**：Visual Studio 项目，用于构建 parse.exe 工具

**关键配置**：
- 平台：Win32
- 配置：SbieRelease
- 输出：控制台应用程序
- 工具集：v143 (Visual Studio 2022)

**自定义构建步骤**：
```batch
# 复制英文文件
copy Sbie-English-1033.txt Text-English-1033.txt

# 收集所有 Text-*.txt 文件
for %%f in (Text-*.txt) do (Set PARSE_ARGS=%%f !PARSE_ARGS!)

# 运行 parse.exe
$(Configuration)\parse %PARSE_ARGS% 2> ParseOutput.log

# 运行消息编译器
mc /h $(MSBuildProjectDirectory)\$(Configuration) /r $(MSBuildProjectDirectory)\$(Configuration) -u $(MSBuildProjectDirectory)\msgs.mc
```

**输出**：
- `msgs.rc` - 消息资源脚本
- `msgs.h` - 消息头文件
- `ParseOutput.log` - 解析日志

---

### 8. SboxMsg.vcxproj - 消息 DLL 项目文件

**文件作用**：Visual Studio 项目，用于构建 SbieMsg.dll

**关键配置**：
- 类型：动态链接库（DLL）
- 平台：Win32, x64, ARM64
- 配置：SbieRelease
- 无入口点（NoEntryPoint=true）- 纯资源 DLL

**输入文件**：
- `resource.rc` - 资源脚本
- `msgs.h` - 消息头文件
- `sbiemsg.def` - DLL 定义

**输出**：
- `SbieMsg.dll` - 包含所有语言消息资源的 DLL

---

## 消息文本文件格式

### 文件命名规范

1. **主文件**：`Sbie-English-1033.txt`
2. **翻译文件**：`Text-{Language}-{LCID}.txt`
   - Language: 语言名称（如 French, German, SimpChinese）
   - LCID: Windows 语言代码标识符

### 消息格式规范

```
NNNN;[facility];[severity];VV
消息文本（可多行）
.
```

**字段说明**：
- `NNNN`：4位消息编号（1000-9999）
- `facility`：消息设施类型
  - `txt` - 纯文本
  - `evt` - 事件日志
  - `pop` - 弹出窗口
  - `evt;pop` - 事件+弹出
  - `ins` - NSIS 安装文本
- `severity`：严重性（仅用于 evt/pop）
  - `inf` - 信息
  - `wrn` - 警告
  - `err` - 错误
- `VV`：2位版本号（01-99）
- `.`：消息结束标记（单独一行）

### 消息示例

```
1101;evt;inf;01
SBIE1101 Sandboxie driver (SbieDrv) version %2 initialized
.

1153;evt;pop;err;01
SBIE1153 Sandboxie initialization failed.  Close all programs and then re-install Sandboxie  OR  restart your computer.
.

2101;txt;01
Sandboxie Control
.

3101;ins;01
Sandboxie is already installed on this computer.
.
```

---

## 支持的语言列表

该系统支持 **32 种语言**：

| 语言 | LCID | 文件名 |
|------|------|--------|
| Albanian | 1052 | Text-Albanian-1052.txt |
| Arabic | 1025 | Text-Arabic-1025.txt |
| Bulgarian | 1026 | Text-Bulgarian-1026.txt |
| Croatian | 1050 | Text-Croatian-1050.txt |
| Czech | 1029 | Text-Czech-1029.txt |
| Danish | 1030 | Text-Danish-1030.txt |
| Dutch | 1043 | Text-Dutch-1043.txt |
| English | 1033 | Sbie-English-1033.txt |
| Estonian | 1061 | Text-Estonian-1061.txt |
| Farsi | 1065 | Text-Farsi-1065.txt |
| Finnish | 1035 | Text-Finnish-1035.txt |
| French | 1036 | Text-French-1036.txt |
| German | 1031 | Text-German-1031.txt |
| Greek | 1032 | Text-Greek-1032.txt |
| Hebrew | 1037 | Text-Hebrew-1037.txt |
| Hungarian | 1038 | Text-Hungarian-1038.txt |
| Indonesian | 1057 | Text-Indonesian-1057.txt |
| Italian | 1040 | Text-Italian-1040.txt |
| Japanese | 1041 | Text-Japanese-1041.txt |
| Korean | 1042 | Text-Korean-1042.txt |
| Macedonian | 1071 | Text-Macedonian-1071.txt |
| Norwegian | 1044 | Text-Norwegian-1044.txt |
| Polish | 1045 | Text-Polish-1045.txt |
| Portuguese | 2070 | Text-Portuguese-2070.txt |
| Portuguese (Brazil) | 1046 | Text-PortugueseBr-1046.txt |
| Russian | 1049 | Text-Russian-1049.txt |
| Simplified Chinese | 2052 | Text-SimpChinese-2052.txt |
| Slovak | 1051 | Text-Slovak-1051.txt |
| Spanish | 1034 | Text-Spanish-1034.txt |
| Swedish | 1053 | Text-Swedish-1053.txt |
| Traditional Chinese | 1028 | Text-TradChinese-1028.txt |
| Turkish | 1055 | Text-Turkish-1055.txt |
| Ukrainian | 1058 | Text-Ukrainian-1058.txt |

---

## 构建流程

### 完整构建流程图

```
1. 编译 parse.c
   ↓
2. 生成 parse.exe
   ↓
3. 复制 Sbie-English-1033.txt → Text-English-1033.txt
   ↓
4. 运行 parse.exe Text-English-1033.txt Text-*.txt
   ↓
5. 生成 msgs.mc（消息编译器输入文件）
   ↓
6. 生成 SbieRelease\NsisText_*.txt（NSIS 语言文件）
   ↓
7. 运行 mc.exe msgs.mc
   ↓
8. 生成 SbieRelease\msgs.h（消息常量定义）
   ↓
9. 生成 SbieRelease\msgs.rc（消息资源脚本）
   ↓
10. 生成 SbieRelease\MSG*.bin（各语言二进制资源）
   ↓
11. 编译 resource.rc（包含 msgs.rc）
   ↓
12. 链接生成 SbieMsg.dll
```

### 关键工具

1. **parse.exe**：自定义消息解析器
2. **mc.exe**：Windows 消息编译器（Message Compiler）
3. **rc.exe**：Windows 资源编译器（Resource Compiler）

---

## 消息编号分类

根据消息文件内容，消息按功能模块分类：

### 1000-1999: 驱动程序和核心系统
- **1101-1122**：SbieDrv 驱动初始化和错误
- **1151-1199**：驱动运行时错误
- **1201-1299**：系统配置和注册表错误
- **1301-1399**：进程管理和沙箱操作

### 2000-2999: 服务和 API
- **2101-2199**：SbieSvc 服务消息
- **2201-2299**：API 钩子和拦截
- **2301-2399**：进程注入和监控

### 3000-3999: 用户界面
- **3101-3199**：控制面板文本
- **3201-3299**：对话框和菜单
- **3301-3399**：设置和配置界面

### 4000-4999: 安装程序（NSIS）
- **4101-4199**：安装向导文本
- **4201-4299**：卸载程序文本

---

## 使用场景

### 1. 添加新消息

1. 编辑 `Sbie-English-1033.txt`，添加新消息
2. 运行构建，parse.exe 会检测到新消息
3. 运行 `RunReport.bat` 生成翻译报告
4. 翻译人员根据报告更新各语言文件
5. 重新构建生成更新的 SbieMsg.dll

### 2. 更新现有消息

1. 修改消息文本
2. 增加版本号（如 01 → 02）
3. parse.exe 会自动使用新版本
4. 旧版本会被自动丢弃

### 3. 在代码中使用消息

```c
// 在 C/C++ 代码中
#include "msgs.h"

// 使用消息常量
DWORD msgId = MSG_1101;

// 从资源加载消息文本
FormatMessage(
    FORMAT_MESSAGE_FROM_HMODULE,
    hSbieMsgDll,
    MSG_1101,
    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
    buffer,
    bufferSize,
    args
);
```

---

## 技术特点

### 1. 版本控制
- 每个消息都有版本号
- 自动保留最新版本
- 防止消息重复定义

### 2. 多语言支持
- 支持 32 种语言
- 自动检测缺失翻译
- 生成翻译报告

### 3. 编码支持
- UTF-16 LE（带 BOM）
- UTF-8（带 BOM）
- 自动检测和转换

### 4. 消息分类
- 事件日志（系统日志）
- 弹出窗口（用户提示）
- 纯文本（UI 标签）
- 安装程序文本（NSIS）

### 5. 严重性级别
- 信息（Informational）
- 警告（Warning）
- 错误（Error）

### 6. 参数化消息
- 支持 `%1`, `%2` 等参数占位符
- 使用 `FormatMessage` API 格式化

---

## 依赖关系

```
parse.c
  ├── common/list.h (链表数据结构)
  ├── common/list.c (链表实现)
  └── Windows API (文件、内存、字符串处理)

resource.rc
  ├── msgs/SbieRelease/msgs.rc (生成的消息资源)
  └── common/my_version.h (版本信息)

SbieMsg.dll
  └── 被 Sandboxie 所有组件使用
      ├── SbieDrv.sys (驱动程序)
      ├── SbieSvc.exe (服务)
      ├── SbieCtrl.exe (控制面板)
      └── 其他组件
```

---

## 总结

`msgs` 目录实现了一个完整的**多语言消息资源管理系统**，具有以下特点：

1. **自动化构建**：通过自定义工具 parse.exe 自动处理所有语言文件
2. **版本管理**：支持消息版本控制，自动保留最新版本
3. **质量保证**：自动生成翻译报告，确保所有语言完整性
4. **标准集成**：生成标准 Windows 消息资源，与系统完美集成
5. **多目标支持**：同时支持应用程序和 NSIS 安装程序
6. **可维护性**：文本格式简单，易于翻译人员编辑

该系统是 Sandboxie 国际化支持的基础设施，确保全球用户都能使用本地化的界面和消息。
