require('dotenv').config();
const express = require("express");
const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawn, exec } = require("child_process");
const app = express();
app.use(express.json());
const commandToRun = "cd ~ && bash serv00keep.sh";
const username = os.userInfo().username;
const lowerUsername = username.toLowerCase();
const logDir = path.join(os.homedir(), "domains", `${lowerUsername}.serv00.net`, "logs");
const listFilePath = path.join(logDir, "list.txt");
const uuidFilePath = path.join(logDir, "UUID.txt");
const processViewEnabled = process.env.ENABLE_PROCESS_VIEW === "true";

function readTrimmedFile(filePath) {
    try {
        return fs.readFileSync(filePath, "utf8").trim();
    } catch {
        return "";
    }
}

function resolveWebToken() {
    return process.env.WEB_TOKEN || readTrimmedFile(uuidFilePath);
}

function resolveListAccessKey() {
    return process.env.LIST_ACCESS_KEY || readTrimmedFile(uuidFilePath);
}

function getProvidedToken(req) {
    const headerToken = req.get("x-web-token");
    return headerToken || req.query.token || "";
}

function isLocalRequest(req) {
    const remoteAddress = req.socket?.remoteAddress || "";
    return ["127.0.0.1", "::1", "::ffff:127.0.0.1"].includes(remoteAddress);
}

function requireToken(req, res, next) {
    const expectedToken = resolveWebToken();
    if (!expectedToken) {
        return res.status(503).json({ error: "WEB_TOKEN not configured" });
    }

    if (getProvidedToken(req) !== expectedToken) {
        return res.status(403).json({ error: "Forbidden" });
    }

    next();
}

function runCustomCommand() {
    exec(commandToRun, (err, stdout) => {
        if (err) console.error("执行错误:", err);
        else console.log("执行成功:", stdout);
    });
}
app.get("/up", requireToken, (_req, res) => {
    runCustomCommand();
    res.status(202).type("html").send("<pre>Serv00-name服务器网页保活启动：Serv00-name！UP！UP！UP！</pre>");
});
app.get("/re", requireToken, (_req, res) => {
    const additionalCommands = `
        USERNAME=$(whoami | tr '[:upper:]' '[:lower:]')
        FULL_PATH="/home/\${USERNAME}/domains/\${USERNAME}.serv00.net/logs"
        cd "$FULL_PATH"
        pkill -f 'run -c con' || echo "无进程可终止，准备执行重启……"
        sbb="$(cat sb.txt 2>/dev/null)"
        nohup ./"$sbb" run -c config.json >/dev/null 2>&1 &
        sleep 2
        (cd ~ && bash serv00keep.sh >/dev/null 2>&1) &  
        echo '主程序重启成功，请检测三个主节点是否可用，如不可用，可再次刷新重启网页或者重置端口'
    `;
    exec(additionalCommands, (err, stdout, stderr) => {
        console.log('stdout:', stdout);
        console.error('stderr:', stderr);
        if (err) {
            return res.status(500).json({ error: "主程序重启失败" });
        }
        res.type('text').send('主程序重启成功，请检测三个主节点是否可用，如不可用，可再次刷新重启网页或者重置端口');
    });
}); 

const changeportCommands = "cd ~ && bash webport.sh"; 
function runportCommand(res) {
exec(changeportCommands, { maxBuffer: 1024 * 1024 * 10 }, (err, stdout, stderr) => {
        console.log('stdout:', stdout);
        console.error('stderr:', stderr);
        if (err) {
            console.error('Execution error:', err);
            return res.status(500).json({ error: "节点端口重置失败" });
        }
        if (stderr) {
            console.error('stderr output:', stderr);
            return res.status(500).json({ error: "节点端口重置失败" });
        }
        res.type('html').send('<pre>重置三个节点端口完成！请立即关闭本网页并稍等20秒，将主页后缀改为 /list/你的uuid 可查看更新端口后的节点及订阅信息</pre>');
    });
}
app.get("/rp", requireToken, (_req, res) => {
   runportCommand(res);
});
app.get("/list/:accessKey", (req, res) => {
    const expectedAccessKey = resolveListAccessKey();
    if (!expectedAccessKey || req.params.accessKey !== expectedAccessKey) {
        return res.status(403).json({ error: "Forbidden" });
    }

    try {
        res.type('text').send(fs.readFileSync(listFilePath, 'utf8'));
    } catch (error) {
        console.error(`读取订阅信息失败: ${error.message}`);
        return res.status(404).json({ error: "订阅信息不存在" });
    }
});

app.get("/jc", requireToken, (req, res) => {
    if (!processViewEnabled && !isLocalRequest(req)) {
        return res.status(404).json({ error: "Not Found" });
    }

    const ps = spawn("ps", ["aux"]);
    res.type("text");
    ps.stdout.on("data", (data) => res.write(data));
    ps.stderr.on("data", (data) => res.write(`Error: ${data}`));
    ps.on("close", (code) => {
        if (code !== 0) {
            res.status(500).send(`ps aux 进程退出，错误码: ${code}`);
        } else {
            res.end();
        }
    });
});

app.use((_req, res) => {
    res.status(404).json({ error: "Not Found" });
});
setInterval(runCustomCommand, (2 * 60 + 15) * 60 * 1000);
const port = Number(process.env.PORT || 3000);
const host = process.env.SERVER_HOST || "127.0.0.1";
app.listen(port, host, () => {
    console.log(`服务器运行在 ${host}:${port}`);
    runCustomCommand();
});
