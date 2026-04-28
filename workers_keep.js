addEventListener('scheduled', event => event.waitUntil(handleScheduled()));
// 配合甬哥的serv00的SSH脚本或者Github/VPS/软路由脚本，生成保活网页与重启网页
// 每个保活/up网页或每个重启/re网页之间用空格或者，或者,间隔开，网页前带 http:// 或 https://
// 安全提示：管理网页现在需要携带 token，例如 http://example.serv00.net/up?token=YOUR_WEB_TOKEN
const urlString = 'http://保活网页1?token=YOUR_WEB_TOKEN http://重启网页2?token=YOUR_WEB_TOKEN';
const urls = urlString.split(/[\s,，]+/);
const TIMEOUT = 5000;
async function fetchWithTimeout(url) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), TIMEOUT);
  try {
    await fetch(url, { signal: controller.signal });
    console.log(`✅ 成功: ${url}`);
  } catch (error) {
    console.warn(`❌ 访问失败: ${url}, 错误: ${error.message}`);
  } finally {
    clearTimeout(timeout);
  }
}
async function handleScheduled() {
  console.log('⏳ 任务开始');
  await Promise.all(urls.map(fetchWithTimeout));
  console.log('📊 任务结束');
}
