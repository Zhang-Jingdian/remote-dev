# 💻 用户工作空间

这是您的专用开发目录。在这里创建和管理您的项目。

## 使用方法

```bash
# 创建新项目
mkdir my-project
cd my-project

# 编辑代码
echo "print('Hello World')" > main.py

# 同步并运行
cd ../..
./dev remote-run "python3 work/my-project/main.py"
```

## 注意事项

- 此目录会自动同步到远程开发环境
- 请避免放置大文件或二进制文件
- `.git` 目录会被自动排除同步
