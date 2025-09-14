#!/usr/bin/env python3
"""
PhotoEnhanceAI API Test Client
Simple test script to validate API functionality
"""

import asyncio
import httpx
import time
from pathlib import Path

API_BASE_URL = "http://localhost:8000"

async def test_api():
    """Test the PhotoEnhanceAI API"""
    async with httpx.AsyncClient(timeout=300.0) as client:
        
        print("🧪 Testing PhotoEnhanceAI API...")
        print(f"🌐 API Base URL: {API_BASE_URL}")
        print()
        
        # Test 1: Health check
        print("1️⃣ Testing health endpoint...")
        try:
            response = await client.get(f"{API_BASE_URL}/health")
            if response.status_code == 200:
                print("✅ Health check passed")
                print(f"   Response: {response.json()}")
            else:
                print(f"❌ Health check failed: {response.status_code}")
                return
        except Exception as e:
            print(f"❌ Health check error: {e}")
            return
        
        print()
        
        # Test 2: Root endpoint
        print("2️⃣ Testing root endpoint...")
        try:
            response = await client.get(f"{API_BASE_URL}/")
            if response.status_code == 200:
                print("✅ Root endpoint works")
                data = response.json()
                print(f"   Service: {data.get('service')}")
                print(f"   Version: {data.get('version')}")
            else:
                print(f"❌ Root endpoint failed: {response.status_code}")
        except Exception as e:
            print(f"❌ Root endpoint error: {e}")
        
        print()
        
        # Test 3: Image enhancement (if sample image exists)
        sample_image = Path("input/sample_input.jpg")
        if sample_image.exists():
            print("3️⃣ Testing image enhancement...")
            
            try:
                # Upload image
                with open(sample_image, "rb") as f:
                    files = {"file": ("test_image.jpg", f, "image/jpeg")}
                    params = {"tile_size": 256, "quality_level": "fast"}  # Fast for testing
                    
                    print("   📤 Uploading image...")
                    response = await client.post(
                        f"{API_BASE_URL}/api/v1/enhance",
                        files=files,
                        params=params
                    )
                
                if response.status_code == 200:
                    task_data = response.json()
                    task_id = task_data["task_id"]
                    print(f"✅ Image uploaded successfully")
                    print(f"   Task ID: {task_id}")
                    
                    # Poll for completion
                    print("   ⏳ Waiting for processing...")
                    max_wait = 300  # 5 minutes
                    start_time = time.time()
                    
                    while time.time() - start_time < max_wait:
                        status_response = await client.get(f"{API_BASE_URL}/api/v1/status/{task_id}")
                        
                        if status_response.status_code == 200:
                            status_data = status_response.json()
                            status = status_data["status"]
                            message = status_data["message"]
                            progress = status_data.get("progress", 0)
                            
                            print(f"   📊 Status: {status} ({progress*100:.1f}%) - {message}")
                            
                            if status == "completed":
                                print("✅ Processing completed!")
                                
                                # Try to download result
                                download_response = await client.get(f"{API_BASE_URL}/api/v1/download/{task_id}")
                                if download_response.status_code == 200:
                                    # Save result
                                    result_path = Path("examples/api_test_result.jpg")
                                    with open(result_path, "wb") as f:
                                        f.write(download_response.content)
                                    print(f"✅ Result saved to: {result_path}")
                                    
                                    # Get file size
                                    size_mb = result_path.stat().st_size / (1024 * 1024)
                                    print(f"   📊 Result size: {size_mb:.1f}MB")
                                else:
                                    print(f"❌ Download failed: {download_response.status_code}")
                                break
                                
                            elif status == "failed":
                                error = status_data.get("error", "Unknown error")
                                print(f"❌ Processing failed: {error}")
                                break
                            
                            # Wait before next check
                            await asyncio.sleep(5)
                        else:
                            print(f"❌ Status check failed: {status_response.status_code}")
                            break
                    else:
                        print("⏰ Timeout waiting for processing")
                        
                else:
                    print(f"❌ Image upload failed: {response.status_code}")
                    print(f"   Error: {response.text}")
                    
            except Exception as e:
                print(f"❌ Enhancement test error: {e}")
        else:
            print("3️⃣ Skipping enhancement test (no sample image found)")
            print(f"   Expected: {sample_image}")
        
        print()
        print("🎉 API testing completed!")

def main():
    """Run the API tests"""
    print("PhotoEnhanceAI API Test Client")
    print("=" * 40)
    
    # Check if we're in the right directory
    if not Path("api/main.py").exists():
        print("❌ Please run this script from the PhotoEnhanceAI project root directory")
        return
    
    try:
        asyncio.run(test_api())
    except KeyboardInterrupt:
        print("\n🛑 Test interrupted by user")
    except Exception as e:
        print(f"❌ Test failed with error: {e}")

if __name__ == "__main__":
    main()
