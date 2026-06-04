#!/usr/bin/env node

const args = process.argv.slice(2);

function takeFlag(name, fallback) {
  const index = args.indexOf(name);
  if (index === -1) return fallback;
  const value = args[index + 1];
  args.splice(index, value === undefined ? 1 : 2);
  return value ?? fallback;
}

const help = args.includes('--help') || args.includes('-h');
if (help) {
  console.log(`Usage:
  zai "Explain this bug"
  echo "Summarize this" | zai
  zai --model glm-5 "Write a unit test"

Env:
  ZAI_API_KEY       Required Z.ai API key
  ZAI_MODEL         Defaults to glm-5.1
  ZAI_BASE_URL      Defaults to https://api.z.ai/api/paas/v4
  ZAI_THINKING      enabled or disabled, defaults to enabled
  ZAI_SHOW_REASONING=1 prints reasoning_content when returned
`);
  process.exit(0);
}

const model = takeFlag('--model', process.env.ZAI_MODEL || 'glm-5.1');
const system = takeFlag('--system', 'You are a concise, practical coding assistant.');
const maxTokens = Number(takeFlag('--max-tokens', process.env.ZAI_MAX_TOKENS || '4096'));
const temperature = Number(takeFlag('--temperature', process.env.ZAI_TEMPERATURE || '1'));
const thinking = args.includes('--no-thinking')
  ? 'disabled'
  : process.env.ZAI_THINKING || 'enabled';
const jsonMode = args.includes('--json');
if (jsonMode) args.splice(args.indexOf('--json'), 1);
if (args.includes('--no-thinking')) args.splice(args.indexOf('--no-thinking'), 1);

const apiKey = process.env.ZAI_API_KEY;
if (!apiKey) {
  console.error('Missing ZAI_API_KEY. Add it to ~/.zai.env, then run: source ~/.zshrc');
  process.exit(1);
}

async function readStdin() {
  if (process.stdin.isTTY) return '';
  const chunks = [];
  for await (const chunk of process.stdin) chunks.push(chunk);
  return Buffer.concat(chunks).toString('utf8').trim();
}

const prompt = args.join(' ').trim() || await readStdin();
if (!prompt) {
  console.error('No prompt provided. Run: zai "hello" or zai --help');
  process.exit(1);
}

const baseUrl = (process.env.ZAI_BASE_URL || 'https://api.z.ai/api/paas/v4').replace(/\/$/, '');
const response = await fetch(`${baseUrl}/chat/completions`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${apiKey}`,
  },
  body: JSON.stringify({
    model,
    messages: [
      {role: 'system', content: system},
      {role: 'user', content: prompt},
    ],
    thinking: {type: thinking},
    max_tokens: maxTokens,
    temperature,
    ...(jsonMode ? {response_format: {type: 'json_object'}} : {}),
  }),
});

const text = await response.text();
let body;
try {
  body = JSON.parse(text);
} catch (_) {
  body = text;
}

if (!response.ok) {
  console.error(`Z.ai request failed (${response.status}):`);
  console.error(typeof body === 'string' ? body : JSON.stringify(body, null, 2));
  process.exit(1);
}

const message = body?.choices?.[0]?.message;
if (process.env.ZAI_SHOW_REASONING === '1' && message?.reasoning_content) {
  console.log('[reasoning]');
  console.log(message.reasoning_content.trim());
  console.log('\n[answer]');
}

const content = message?.content ?? JSON.stringify(body, null, 2);
console.log(String(content).trim());
