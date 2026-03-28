#!/usr/bin/env python3
"""
Sandboxie 代码搜索工具
用于快速搜索函数、结构体、配置项等
"""

import os
import re
import sys
import argparse
from pathlib import Path
from typing import List, Dict, Tuple

# 项目根目录
PROJECT_ROOT = Path(__file__).parent.parent.parent.parent

# 核心代码目录
CORE_DIRS = [
    PROJECT_ROOT / "Sandboxie" / "core" / "drv",
    PROJECT_ROOT / "Sandboxie" / "core" / "dll",
    PROJECT_ROOT / "Sandboxie" / "core" / "svc",
    PROJECT_ROOT / "SandboxiePlus" / "QSbieAPI",
    PROJECT_ROOT / "SandboxiePlus" / "SandMan",
]

# 文件扩展名
CODE_EXTENSIONS = ['.c', '.cpp', '.h', '.hpp']


def search_function(function_name: str, dirs: List[Path] = None) -> List[Tuple[Path, int, str]]:
    """搜索函数定义"""
    if dirs is None:
        dirs = CORE_DIRS
    
    results = []
    # 匹配函数定义的正则表达式
    pattern = re.compile(
        rf'^\s*(?:static\s+)?(?:inline\s+)?(?:\w+\s+)*{re.escape(function_name)}\s*\(',
        re.MULTILINE
    )
    
    for dir_path in dirs:
        if not dir_path.exists():
            continue
        
        for file_path in dir_path.rglob('*'):
            if file_path.suffix not in CODE_EXTENSIONS:
                continue
            
            try:
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                    for match in pattern.finditer(content):
                        line_num = content[:match.start()].count('\n') + 1
                        line = content.split('\n')[line_num - 1].strip()
                        results.append((file_path, line_num, line))
            except Exception as e:
                print(f"Error reading {file_path}: {e}", file=sys.stderr)
    
    return results


def search_struct(struct_name: str, dirs: List[Path] = None) -> List[Tuple[Path, int, str]]:
    """搜索结构体定义"""
    if dirs is None:
        dirs = CORE_DIRS
    
    results = []
    # 匹配结构体定义的正则表达式
    pattern = re.compile(
        rf'^\s*(?:typedef\s+)?struct\s+(?:_)?{re.escape(struct_name)}\s*{{',
        re.MULTILINE
    )
    
    for dir_path in dirs:
        if not dir_path.exists():
            continue
        
        for file_path in dir_path.rglob('*'):
            if file_path.suffix not in CODE_EXTENSIONS:
                continue
            
            try:
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                    for match in pattern.finditer(content):
                        line_num = content[:match.start()].count('\n') + 1
                        line = content.split('\n')[line_num - 1].strip()
                        results.append((file_path, line_num, line))
            except Exception as e:
                print(f"Error reading {file_path}: {e}", file=sys.stderr)
    
    return results


def search_config(config_name: str) -> List[Tuple[Path, int, str]]:
    """搜索配置项使用"""
    results = []
    
    # 搜索驱动层配置读取
    drv_conf = PROJECT_ROOT / "Sandboxie" / "core" / "drv" / "conf.c"
    if drv_conf.exists():
        try:
            with open(drv_conf, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                pattern = re.compile(rf'Conf_Get.*{re.escape(config_name)}', re.IGNORECASE)
                for match in pattern.finditer(content):
                    line_num = content[:match.start()].count('\n') + 1
                    line = content.split('\n')[line_num - 1].strip()
                    results.append((drv_conf, line_num, line))
        except Exception as e:
            print(f"Error reading {drv_conf}: {e}", file=sys.stderr)
    
    # 搜索配置文件
    templates_ini = PROJECT_ROOT / "Sandboxie" / "install" / "Templates.ini"
    if templates_ini.exists():
        try:
            with open(templates_ini, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                pattern = re.compile(rf'^{re.escape(config_name)}\s*=', re.MULTILINE | re.IGNORECASE)
                for match in pattern.finditer(content):
                    line_num = content[:match.start()].count('\n') + 1
                    line = content.split('\n')[line_num - 1].strip()
                    results.append((templates_ini, line_num, line))
        except Exception as e:
            print(f"Error reading {templates_ini}: {e}", file=sys.stderr)
    
    return results


def search_text(text: str, dirs: List[Path] = None) -> List[Tuple[Path, int, str]]:
    """搜索任意文本"""
    if dirs is None:
        dirs = CORE_DIRS
    
    results = []
    pattern = re.compile(re.escape(text), re.IGNORECASE)
    
    for dir_path in dirs:
        if not dir_path.exists():
            continue
        
        for file_path in dir_path.rglob('*'):
            if file_path.suffix not in CODE_EXTENSIONS:
                continue
            
            try:
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    for line_num, line in enumerate(f, 1):
                        if pattern.search(line):
                            results.append((file_path, line_num, line.strip()))
            except Exception as e:
                print(f"Error reading {file_path}: {e}", file=sys.stderr)
    
    return results


def print_results(results: List[Tuple[Path, int, str]], title: str):
    """打印搜索结果"""
    if not results:
        print(f"\n{title}: 未找到结果")
        return
    
    print(f"\n{title}: 找到 {len(results)} 个结果")
    print("=" * 80)
    
    for file_path, line_num, line in results:
        rel_path = file_path.relative_to(PROJECT_ROOT)
        print(f"\n{rel_path}:{line_num}")
        print(f"  {line}")


def main():
    parser = argparse.ArgumentParser(description='Sandboxie 代码搜索工具')
    parser.add_argument('--function', '-f', help='搜索函数定义')
    parser.add_argument('--struct', '-s', help='搜索结构体定义')
    parser.add_argument('--config', '-c', help='搜索配置项')
    parser.add_argument('--text', '-t', help='搜索任意文本')
    parser.add_argument('--all', '-a', help='搜索所有类型', metavar='NAME')
    
    args = parser.parse_args()
    
    if not any([args.function, args.struct, args.config, args.text, args.all]):
        parser.print_help()
        return
    
    if args.all:
        print(f"搜索: {args.all}")
        print_results(search_function(args.all), "函数定义")
        print_results(search_struct(args.all), "结构体定义")
        print_results(search_config(args.all), "配置项")
        print_results(search_text(args.all), "文本匹配")
    else:
        if args.function:
            print_results(search_function(args.function), f"函数定义: {args.function}")
        
        if args.struct:
            print_results(search_struct(args.struct), f"结构体定义: {args.struct}")
        
        if args.config:
            print_results(search_config(args.config), f"配置项: {args.config}")
        
        if args.text:
            print_results(search_text(args.text), f"文本匹配: {args.text}")


if __name__ == '__main__':
    main()
