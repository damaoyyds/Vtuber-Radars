# Debug Session: background-search

## Status: OPEN

## Issue Description
自动搜索在模拟器上正常工作，但在真机上必须切到前台才能收到消息。

## Environment
- Platform: Android (真机)
- Flutter Version: 3.11.5
- Workmanager Version: 0.9.0

## Hypotheses

### H1: Workmanager 后台任务未被正确触发
**Description**: Android 系统或厂商限制导致 Workmanager