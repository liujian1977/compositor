#!/usr/bin/env python3
"""
批量生成VI品牌Mockup图片 - 模板脚本

复制此脚本，然后填入你的配置和提示词。
"""

import requests
import sys
import json
import os
import time

# ========== 配置区 ==========
OUTPUT_DIR = "work/assets/v6_brand_mockups"  # 输出目录
BASE_URL = "https://aistudio.baidu.com/llm/lmapi/v3"
TOKEN_VALUE=***  # 填入你的token或从baidu-aistudio skill获取

# ========== 提示词配置 ==========
# 提示词模板：使用官方品牌元素，描述准确
PROMPTS = [
    {
        "name": "01_business_card",
        "prompt": "苏州大学名片设计，白色高级纸张质感，左侧为苏州大学官方校徽（深红色圆形，中心\"東\"字书法体，环绕英文\"SOOCHOW UNIVERSITY\"和\"CHINA\"），右上角黑色字样\"苏州大学\"和\"Soochow University\"，中部名片持有者信息：姓名、职务、联系电话、邮箱、地址，底部深红色校训\"养天地正气，法古今完人\"，整体设计简洁、学术、庄重，品牌色：苏大红（#C41E3A）、黑色、白色，尺寸90mm x 54mm，专业商务风格，印刷质感，高清晰度。",
        "output": os.path.join(OUTPUT_DIR, "01_business_card_suda.png")
    },
    # 添加更多提示词...
    # {
    #     "name": "02_letterhead",
    #     "prompt": "...",
    #     "output": ...
    # },
]

# ========== 生成函数 ==========
def generate_image(prompt, output_path, timeout=240):
    """生成单张图片"""
    
    api_url = f"{BASE_URL}/images/generations"
    
    payload = {
        "model": "ERNIE-Image-Turbo",
        "prompt": prompt,
        "response_format": "url",
        "n": 1,
        "size": "1024x1024"
    }
    
    headers = {
        "Authorization": f"Bearer {TOKEN_VALUE}",
        "Content-Type": "application/json"
    }
    
    print(f"  调用API: prompt长度={len(prompt)}字符", file=sys.stderr)
    
    try:
        resp = requests.post(api_url, json=payload, headers=headers, timeout=timeout)
        resp.raise_for_status()
        result = resp.json()
        
        if "error_code" in result:
            error_msg = result.get('error_msg')
            print(f"  ✗ API错误: {error_msg}", file=sys.stderr)
            return None, error_msg
        
        item = result["data"][0]
        url = item.get("url")
        trace = result.get("trace_id", "")
        
        print(f"  ✓ Trace ID: {trace}", file=sys.stderr)
        print(f"  下载图片到: {output_path}", file=sys.stderr)
        
        # 下载图片
        img_resp = requests.get(url, timeout=240)
        img_resp.raise_for_status()
        img_data = img_resp.content
        
        with open(output_path, "wb") as f:
            f.write(img_data)
        
        file_size = len(img_data)
        print(f"  ✓ 保存成功，文件大小: {file_size} bytes", file=sys.stderr)
        
        return {
            "output_path": output_path,
            "file_size": file_size,
            "trace_id": trace
        }, None
        
    except requests.exceptions.HTTPError as e:
        error_msg = f"HTTP错误: {e}"
        print(f"  ✗ {error_msg}", file=sys.stderr)
        if e.response.status_code == 401:
            error_msg = "Access token已过期或无效，请更新token"
        return None, error_msg
    except Exception as e:
        error_msg = f"异常: {str(e)}"
        print(f"  ✗ {error_msg}", file=sys.stderr)
        return None, error_msg

# ========== 主函数 ==========
def main():
    print("=" * 60)
    print("VI品牌Mockup - 批量图片生成")
    print("=" * 60)
    
    # 确保输出目录存在
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    results = []
    
    for i, item in enumerate(PROMPTS, 1):
        print(f"\n[{i}/{len(PROMPTS)}] 生成 {item['name']}...")
        print(f"  输出路径: {item['output']}")
        
        result, error = generate_image(item['prompt'], item['output'])
        
        if result:
            print(f"  ✓ {item['name']} 生成成功")
            results.append({
                "name": item['name'],
                "status": "success",
                **result
            })
        else:
            print(f"  ✗ {item['name']} 生成失败: {error}")
            results.append({
                "name": item['name'],
                "status": "failed",
                "error": error
            })
        
        # 每次请求间隔2秒，避免频繁调用
        if i < len(PROMPTS):
            time.sleep(2)
    
    # 保存结果
    result_file = f"{OUTPUT_DIR}/generation_results.json"
    with open(result_file, 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    
    # 统计
    success_count = sum(1 for r in results if r['status'] == 'success')
    failed_count = len(results) - success_count
    
    print("\n" + "=" * 60)
    print("生成完成")
    print("=" * 60)
    print(f"成功: {success_count}/{len(PROMPTS)}")
    print(f"失败: {failed_count}/{len(PROMPTS)}")
    print(f"结果文件: {result_file}")
    
    # 列出生成的文件
    print("\n生成的文件:")
    for result in results:
        if result['status'] == 'success':
            path = result.get('output_path', 'N/A')
            size = result.get('file_size', 'N/A')
            print(f"  {result['name']}: {path} ({size} bytes)")

if __name__ == "__main__":
    main()