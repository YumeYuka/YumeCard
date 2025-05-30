const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

(async () => {
    const htmlFilePath = process.argv[2];
    const outputImagePath = process.argv[3] || 'screenshot.png';

    if (!htmlFilePath) {
        console.error('错误：请提供HTML文件路径作为第一个参数。');
        process.exit(1);
    }

    const absoluteHtmlPath = path.resolve(htmlFilePath);

    if (!fs.existsSync(absoluteHtmlPath)) {
        console.error(`错误：HTML文件未找到: ${absoluteHtmlPath}`);
        process.exit(1);
    }

    const browser = await puppeteer.launch({
        headless: 'new',
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    const page = await browser.newPage();

    const fileUrl = 'file:///' + absoluteHtmlPath.replace(/\\/g, '/');
    console.log(`正在加载: ${fileUrl}`);
    await page.goto(fileUrl, {waitUntil: 'networkidle0'});

    // 等待字体加载完成
    await page.evaluate(() => document.fonts.ready);

    // 等待.container元素加载
    await page.waitForSelector('.container', {timeout: 5000}).catch(e => {
        console.warn('未找到.container元素，将使用整个页面进行截图。');
    });
    // 查找卡片容器并获取其尺寸，添加边距确保内容完全可见
    const boundingBox = await page.evaluate(() => {
        // 先尝试找到主卡片容器
        const container = document.querySelector('.container');
        if (!container) {
            return {width: 800, height: 600, x: 0, y: 0}; // 默认值
        }

        // 找到卡片内所有内容元素
        const allContentElements = container.querySelectorAll('*');

        // 初始化边界框
        let minX = Infinity, minY = Infinity;
        let maxX = -Infinity, maxY = -Infinity;

        // 遍历所有元素计算真实边界
        allContentElements.forEach(element => {
            const rect = element.getBoundingClientRect();
            if (rect.width > 0 && rect.height > 0) {
                minX = Math.min(minX, rect.left);
                minY = Math.min(minY, rect.top);
                maxX = Math.max(maxX, rect.right);
                maxY = Math.max(maxY, rect.bottom);
            }
        });

        // 添加10px的边距
        const padding = 15;
        return {
            width: maxX - minX + (padding * 2),
            height: maxY - minY + (padding * 2),
            x: minX - padding,
            y: minY - padding
        };
    });    // 设置视口大小，确保足够大以显示整个内容
    const viewportWidth = Math.ceil(boundingBox.width);
    const viewportHeight = Math.ceil(boundingBox.height);

    // 确保视口尺寸足够大
    const minWidth = 1000; // 最小宽度
    const minHeight = 800; // 最小高度

    const finalWidth = Math.max(viewportWidth, minWidth);
    const finalHeight = Math.max(viewportHeight, minHeight);

    console.log(`计算出的视口尺寸: 宽=${finalWidth}, 高=${finalHeight}`);

    await page.setViewport({
        width: finalWidth,
        height: finalHeight
    });

    // 等待短暂延迟确保页面完全渲染
    await new Promise(resolve => setTimeout(resolve, 500));

    console.log(`正在截图并保存到: ${outputImagePath}`);
    // 确保页面完全加载
    await page.evaluate(async () => {
        // 等待可能的动画完成
        return new Promise(resolve => setTimeout(resolve, 300));
    });

    // 重新计算尺寸以确保一切正确
    const finalBox = await page.evaluate(() => {
        const container = document.querySelector('.container');
        if (!container) return null;

        // 获取所有内容元素的边界
        const allElements = Array.from(container.querySelectorAll('*'));

        // 初始化边界值
        let minX = Infinity, minY = Infinity;
        let maxX = -Infinity, maxY = -Infinity;

        // 计算所有元素的最大边界
        allElements.forEach(el => {
            const rect = el.getBoundingClientRect();
            if (rect.width > 0 && rect.height > 0) {
                minX = Math.min(minX, rect.left);
                minY = Math.min(minY, rect.top);
                maxX = Math.max(maxX, rect.right);
                maxY = Math.max(maxY, rect.bottom);
            }
        });

        // 添加边距
        const padding = 20;
        return {
            x: Math.max(0, minX - padding),
            y: Math.max(0, minY - padding),
            width: maxX - minX + (padding * 2),
            height: maxY - minY + (padding * 2)
        };
    });

    const clipBox = finalBox || {
        x: boundingBox.x,
        y: boundingBox.y,
        width: boundingBox.width,
        height: boundingBox.height
    };

    console.log(`最终截图区域: x=${clipBox.x}, y=${clipBox.y}, 宽=${clipBox.width}, 高=${clipBox.height}`);

    // 仅截取卡片区域，确保所有内容都被包含
    await page.screenshot({
        path: outputImagePath,
        clip: clipBox
    });

    await browser.close();
    console.log('截图完成!');
})();

