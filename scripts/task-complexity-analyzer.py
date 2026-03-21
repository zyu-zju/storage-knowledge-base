#!/usr/bin/env python3
"""
任务复杂度分析器
用于评估任务复杂度并推荐合适的模型
"""

import re
from typing import Dict, List, Tuple

class TaskComplexityAnalyzer:
    def __init__(self):
        # 复杂度关键词库
        self.complex_keywords = {
            "high": [
                # 深度分析类
                "分析", "评估", "诊断", "调研", "研究", "探讨",
                # 规划设计类
                "设计", "规划", "架构", "方案", "策略", "蓝图",
                # 问题解决类
                "解决", "优化", "改进", "提升", "突破", "创新",
                # 技术深度类
                "原理", "机制", "算法", "模型", "框架", "体系",
                # 复杂决策类
                "决策", "选择", "比较", "对比", "权衡", "平衡"
            ],
            "medium": [
                # 实施执行类
                "实施", "执行", "部署", "配置", "安装", "搭建",
                # 测试验证类
                "测试", "验证", "检查", "审核", "评估", "验收",
                # 文档编写类
                "编写", "撰写", "整理", "汇总", "报告", "文档",
                # 培训教育类
                "培训", "教育", "指导", "教学", "学习", "掌握"
            ],
            "low": [
                # 基础操作类
                "查看", "检查", "查询", "搜索", "查找", "浏览",
                # 简单处理类
                "整理", "分类", "排序", "过滤", "提取", "转换",
                # 日常维护类
                "维护", "更新", "备份", "清理", "监控", "日志"
            ]
        }
        
        # 存储技术特定复杂任务
        self.storage_complex_tasks = [
            "存储架构设计", "性能优化", "容量规划", "数据迁移",
            "灾难恢复", "高可用设计", "安全加固", "成本优化",
            "多云策略", "合规审计", "技术选型", "基准测试"
        ]
    
    def analyze_task_complexity(self, task_description: str) -> Dict:
        """分析任务复杂度"""
        task_lower = task_description.lower()
        
        # 初始化分数
        complexity_score = 0
        keyword_matches = {"high": [], "medium": [], "low": []}
        
        # 检查关键词匹配
        for level, keywords in self.complex_keywords.items():
            for keyword in keywords:
                if keyword in task_lower:
                    keyword_matches[level].append(keyword)
                    
                    # 根据级别加分
                    if level == "high":
                        complexity_score += 3
                    elif level == "medium":
                        complexity_score += 2
                    else:
                        complexity_score += 1
        
        # 检查存储技术特定任务
        storage_complexity = 0
        storage_tasks_found = []
        for task in self.storage_complex_tasks:
            if task in task_description:
                storage_tasks_found.append(task)
                storage_complexity += 5  # 存储技术任务额外加权
        
        # 计算任务长度复杂度
        length_complexity = min(len(task_description) / 100, 5)  # 每100字符加1分，最多5分
        
        # 总复杂度分数
        total_score = complexity_score + storage_complexity + length_complexity
        
        # 确定复杂度级别
        if total_score >= 15:
            complexity_level = "very_high"
            model_recommendation = "deepseek/deepseek-reasoner"
            reasoning = "需要深度推理和创造性思考"
        elif total_score >= 10:
            complexity_level = "high"
            model_recommendation = "deepseek/deepseek-reasoner"
            reasoning = "需要多步骤逻辑推理"
        elif total_score >= 5:
            complexity_level = "medium"
            model_recommendation = "deepseek/deepseek-chat"
            reasoning = "常规任务，标准处理即可"
        else:
            complexity_level = "low"
            model_recommendation = "deepseek/deepseek-chat"
            reasoning = "简单任务，快速处理"
        
        return {
            "task_description": task_description,
            "complexity_score": round(total_score, 2),
            "complexity_level": complexity_level,
            "model_recommendation": model_recommendation,
            "reasoning": reasoning,
            "keyword_analysis": keyword_matches,
            "storage_tasks_found": storage_tasks_found,
            "breakdown": {
                "keyword_score": complexity_score,
                "storage_task_score": storage_complexity,
                "length_score": round(length_complexity, 2)
            }
        }
    
    def recommend_processing_strategy(self, complexity_analysis: Dict) -> Dict:
        """推荐处理策略"""
        level = complexity_analysis["complexity_level"]
        
        strategies = {
            "very_high": {
                "model": "deepseek/deepseek-reasoner",
                "approach": "分阶段深度分析",
                "steps": [
                    "1. 问题分解和定义",
                    "2. 技术调研和分析",
                    "3. 方案设计和评估",
                    "4. 实施规划和建议",
                    "5. 风险评估和应对"
                ],
                "time_estimate": "2-4小时",
                "output_format": "详细技术报告 + 实施方案"
            },
            "high": {
                "model": "deepseek/deepseek-reasoner",
                "approach": "结构化分析",
                "steps": [
                    "1. 问题分析",
                    "2. 技术方案设计",
                    "3. 实施建议"
                ],
                "time_estimate": "1-2小时",
                "output_format": "技术分析报告"
            },
            "medium": {
                "model": "deepseek/deepseek-chat",
                "approach": "标准处理",
                "steps": [
                    "1. 信息收集",
                    "2. 整理分析",
                    "3. 输出结果"
                ],
                "time_estimate": "30-60分钟",
                "output_format": "整理后的信息"
            },
            "low": {
                "model": "deepseek/deepseek-chat",
                "approach": "快速处理",
                "steps": [
                    "1. 直接处理",
                    "2. 简洁输出"
                ],
                "time_estimate": "5-15分钟",
                "output_format": "简洁答案"
            }
        }
        
        return strategies.get(level, strategies["medium"])

def analyze_example_tasks():
    """分析示例任务"""
    analyzer = TaskComplexityAnalyzer()
    
    example_tasks = [
        # 简单任务
        "查看今天的存储技术新闻",
        "整理本周收集的文章",
        "检查系统状态",
        
        # 中等任务
        "编写存储性能测试报告",
        "部署一个简单的存储测试环境",
        "学习AWS S3的基本概念",
        
        # 复杂任务
        "设计一个企业级云存储架构方案",
        "分析并优化现有存储系统的性能瓶颈",
        "规划从本地存储到云存储的数据迁移策略",
        
        # 非常复杂的任务
        "为金融行业设计符合监管要求的高可用存储架构，需要考虑数据安全、性能、成本和可扩展性",
        "制定多云存储策略，优化全球数据访问性能，同时控制成本并确保数据一致性"
    ]
    
    print("🔍 任务复杂度分析示例")
    print("=" * 60)
    
    for i, task in enumerate(example_tasks, 1):
        print(f"\n任务 {i}: {task}")
        analysis = analyzer.analyze_task_complexity(task)
        strategy = analyzer.recommend_processing_strategy(analysis)
        
        print(f"  复杂度分数: {analysis['complexity_score']}")
        print(f"  复杂度级别: {analysis['complexity_level']}")
        print(f"  推荐模型: {analysis['model_recommendation']}")
        print(f"  处理策略: {strategy['approach']}")
        print(f"  预计时间: {strategy['time_estimate']}")

if __name__ == "__main__":
    # 测试示例任务
    analyze_example_tasks()
    
    # 交互式分析
    print("\n" + "=" * 60)
    print("💡 你可以输入任务描述进行分析:")
    
    analyzer = TaskComplexityAnalyzer()
    
    while True:
        try:
            task = input("\n请输入任务描述 (或输入 'quit' 退出): ")
            if task.lower() == 'quit':
                break
                
            if task.strip():
                analysis = analyzer.analyze_task_complexity(task)
                strategy = analyzer.recommend_processing_strategy(analysis)
                
                print(f"\n📊 分析结果:")
                print(f"  任务: {analysis['task_description']}")
                print(f"  复杂度分数: {analysis['complexity_score']}")
                print(f"  复杂度级别: {analysis['complexity_level']}")
                print(f"  推荐模型: {analysis['model_recommendation']}")
                print(f"  理由: {analysis['reasoning']}")
                
                print(f"\n🔧 处理策略:")
                print(f"  方法: {strategy['approach']}")
                print(f"  步骤:")
                for step in strategy['steps']:
                    print(f"    {step}")
                print(f"  预计时间: {strategy['time_estimate']}")
                print(f"  输出格式: {strategy['output_format']}")
                
                if analysis['storage_tasks_found']:
                    print(f"\n🏢 识别到的存储技术任务: {', '.join(analysis['storage_tasks_found'])}")
                    
        except KeyboardInterrupt:
            break
        except Exception as e:
            print(f"错误: {e}")