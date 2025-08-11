#!/usr/bin/env bash
set -euo pipefail

echo "📖 Bootstrapping Book of Solana (Ethereal UI)…"

# --- sanity checks
if ! command -v node >/dev/null 2>&1; then
  echo "Installing Node.js 18…"
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi
if ! command -v npm >/dev/null 2>&1; then
  echo "npm is required"; exit 1
fi

# --- project root
ROOT="$(pwd)"
APPDIR="$ROOT"
echo "Using repo root: $APPDIR"

# --- write files
mkdir -p styles components utils pages public

cat > package.json <<'JSON'
{
  "name": "book-of-solana",
  "version": "0.2.0",
  "private": true,
  "scripts": {
    "dev": "next dev -p 3000",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "@bundlr-network/client": "^0.10.10",
    "@project-serum/anchor": "^0.29.0",
    "@solana/spl-token": "^0.4.7",
    "@solana/wallet-adapter-base": "^0.9.24",
    "@solana/wallet-adapter-react": "^0.15.35",
    "@solana/wallet-adapter-react-ui": "^0.9.34",
    "@solana/wallet-adapter-wallets": "^0.19.27",
    "@solana/web3.js": "^1.95.3",
    "autoprefixer": "10.4.20",
    "next": "14.2.5",
    "postcss": "8.4.41",
    "react": "18.2.0",
    "react-dom": "18.2.0",
    "tailwindcss": "3.4.10"
  }
}
JSON

cat > next.config.js <<'JS'
module.exports = { reactStrictMode: true };
JS

cat > postcss.config.js <<'JS'
module.exports = { plugins: { tailwindcss: {}, autoprefixer: {}, } };
JS

cat > tailwind.config.js <<'JS'
module.exports = {
  content: ["./pages/**/*.{js,ts,jsx,tsx}","./components/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: { sol: { purple:"#9945FF", teal:"#14F195", blue:"#00D3FF", pink:"#B62AFF", gold:"#FFC34D" } },
      dropShadow: { glow: "0 0 12px rgba(153,69,255,.6), 0 0 24px rgba(0,211,255,.35)" }
    }
  },
  plugins: []
};
JS

cat > tsconfig.json <<'JSON'
{
  "compilerOptions": {
    "target": "es2020",
    "lib": ["dom", "es2020"],
    "jsx": "preserve",
    "module": "esnext",
    "moduleResolution": "bundler",
    "strict": true,
    "baseUrl": ".",
    "paths": { "@/*": ["*"] }
  },
  "exclude": ["node_modules"]
}
JSON

cat > styles/globals.css <<'CSS'
@tailwind base; @tailwind components; @tailwind utilities;
:root{color-scheme:dark} body{background:#000;color:#fff}
.card{background:#111827b3;border:1px solid #262626;border-radius:1rem;padding:1.25rem}
.btn{padding:.5rem 1rem;border-radius:.75rem;background:#ffffff1a;transition:.2s}
.btn:hover{background:#ffffff33}
.input{width:100%;background:#00000066;border:1px solid #262626;border-radius:.75rem;padding:.75rem;outline:none}
.input:focus{box-shadow:0 0 0 2px #9945FF66}
.starry{position:fixed;inset:0;pointer-events:none;opacity:.35;background-image:
radial-gradient(1px 1px at 10% 20%, rgba(255,255,255,.6) 0, transparent 60%),
radial-gradient(1px 1px at 30% 80%, rgba(255,255,255,.5) 0, transparent 60%),
radial-gradient(1px 1px at 70% 40%, rgba(255,255,255,.5) 0, transparent 60%),
radial-gradient(1px 1px at 90% 60%, rgba(255,255,255,.4) 0, transparent 60%);
}
CSS

cat > .env.example <<'ENV'
NEXT_PUBLIC_NETWORK=mainnet-beta
NEXT_PUBLIC_TREASURY=Fo3ZwcugwUfn2Ye7MBdQyHjfqeeZ4nUrDRQ7oQ7MJsfd
NEXT_PUBLIC_BOOS_MINT=GFJfGXKMZb9PWRMXWSb4WAkguiokknpu72v4KQwPmdqA
NEXT_PUBLIC_BUNDLR_NODE=https://node1.bundlr.network
NEXT_PUBLIC_BUNDLR_CURRENCY=solana
ENV

cat > components/Wallet.tsx <<'TSX'
import React, { useMemo } from 'react';
import { ConnectionProvider, WalletProvider } from '@solana/wallet-adapter-react';
import { WalletModalProvider } from '@solana/wallet-adapter-react-ui';
import { PhantomWalletAdapter, SolflareWalletAdapter, BackpackWalletAdapter } from '@solana/wallet-adapter-wallets';
require('@solana/wallet-adapter-react-ui/styles.css');
export default function Wallet({ children }: { children: React.ReactNode }) {
  const endpoint = useMemo(() => 'https://api.mainnet-beta.solana.com', []);
  const wallets = useMemo(() => [new PhantomWalletAdapter(), new SolflareWalletAdapter(), new BackpackWalletAdapter()], []);
  return (
    <ConnectionProvider endpoint={endpoint}>
      <WalletProvider wallets={wallets} autoConnect>
        <WalletModalProvider>{children}</WalletModalProvider>
      </WalletProvider>
    </ConnectionProvider>
  );
}
TSX

cat > utils
cat > utils/uploader.ts <<'TS'
import Bundlr from "@bundlr-network/client";
export async function uploadJSONViaBundlr(json: any, provider: any) {
  const node = process.env.NEXT_PUBLIC_BUNDLR_NODE || "https://node1.bundlr.network";
  const currency = process.env.NEXT_PUBLIC_BUNDLR_CURRENCY || "solana";
  // @ts-ignore
  const bundlr = new Bundlr(node, currency, provider);
  await bundlr.ready();
  const tx = await bundlr.upload(Buffer.from(JSON.stringify(json)), {
    tags: [{ name: "Content-Type", value: "application/json" }, { name: "App-Name", value: "BookOfSolana" }],
  });
  return `https://arweave.net/${tx.id}`;
}
TS

cat > utils/hash.ts <<'TS'
export async function sha256Hex(str: string) {
  const enc = new TextEncoder();
  const data = enc.encode(str);
  const hash = await crypto.subtle.digest('SHA-256', data);
  return Array.from(new Uint8Array(hash)).map(b => b.toString(16).padStart(2, '0')).join('');
}
TS

cat > utils/transferBoos.ts <<'TS'
import { PublicKey, Transaction } from "@solana/web3.js";
import { getAssociatedTokenAddress, createTransferInstruction } from "@solana/spl-token";
import type { Connection } from "@solana/web3.js";
export async function transferBoos(connection: Connection, wallet: any, amountBoos: number) {
  const BOOS_MINT = new PublicKey(process.env.NEXT_PUBLIC_BOOS_MINT!);
  const TREASURY = new PublicKey(process.env.NEXT_PUBLIC_TREASURY!);
  const decimals = 6; // BOOS uses 6 decimals
  const amount = Math.floor(amountBoos * (10 ** decimals));
  const owner = wallet.publicKey;
  if (!owner) throw new Error("Wallet not connected");
  const fromAta = await getAssociatedTokenAddress(BOOS_MINT, owner);
  const toAta = await getAssociatedTokenAddress(BOOS_MINT, TREASURY, true);
  const ix = createTransferInstruction(fromAta, toAta, owner, amount);
  const tx = new Transaction().add(ix);
  tx.feePayer = owner;
  const { blockhash } = await connection.getLatestBlockhash();
  tx.recentBlockhash = blockhash;
  const signed = await wallet.signTransaction(tx);
  const sig = await connection.sendRawTransaction(signed.serialize());
  await connection.confirmTransaction(sig, "confirmed");
  return sig;
}
TS

mkdir -p public
cat > public/logo-book.svg <<'SVG'
<svg width="120" height="90" viewBox="0 0 120 90" xmlns="http://www.w3.org/2000/svg" fill="none">
  <defs>
    <linearGradient id="g" x1="0" y1="0" x2="120" y2="0">
      <stop offset="0" stop-color="#14F195"/>
      <stop offset="0.5" stop-color="#00D3FF"/>
      <stop offset="1" stop-color="#9945FF"/>
    </linearGradient>
  </defs>
  <path d="M10 25c18-8 34-8 50 0 16-8 32-8 50 0v42c-18-8-34-8-50 0-16-8-32-8-50 0V25z" stroke="url(#g)" stroke-width="2.5" opacity="0.9"/>
  <path d="M60 25v42" stroke="url(#g)" stroke-width="2.5" opacity="0.9"/>
  <path d="M60 49c4-7 14-11 40-10" stroke="url(#g)" stroke-width="2" opacity="0.6"/>
  <path d="M60 49c-4-7-14-11-40-10" stroke="url(#g)" stroke-width="2" opacity="0.6"/>
  <circle cx="60" cy="20" r="3" fill="#00D3FF"/>
</svg>
SVG

cat > pages/_app.tsx <<'TSX'
import type { AppProps } from 'next/app'
import '@/styles/globals.css'
import Wallet from '@/components/Wallet'
import Link from 'next/link'
export default function App({ Component, pageProps }: AppProps) {
  return (
    <Wallet>
      <div className="min-h-screen relative" style={{backgroundImage:'radial-gradient(1200px 600px at 50% -10%, rgba(0,211,255,.25), transparent 60%), radial-gradient(1200px 600px at 80% 10%, rgba(153,69,255,.25), transparent 60%), radial-gradient(1200px 700px at 20% 10%, rgba(20,241,149,.2), transparent 60%)'}}>
        <div className="starry"></div>
        <header className="sticky top-0 z-50 backdrop-blur bg-black/40 border-b border-neutral-900">
          <div className="mx-auto max-w-5xl px-4 py-3 flex items-center justify-between">
            <Link href="/" className="flex items-center gap-3 text-xl font-semibold">
              <img src="/logo-book.svg" alt="Book of Solana" className="w-7 h-7 drop-shadow-glow"/>
              <span>Book of Solana</span>
            </Link>
            <nav className="flex gap-4 text-sm">
              <Link href="/feed" className="hover:underline">Feed</Link>
              <a href="https://arweave.net" target="_blank" rel="noreferrer" className="text-neutral-400 hover:text-white">Arweave</a>
            </nav>
          </div>
        </header>
        <main className="mx-auto max-w-5xl px-4 py-8">
          <Component {...pageProps} />
        </main>
      </div>
    </Wallet>
  )
}
TSX

cat > pages/index.tsx <<'TSX'
import { useConnection, useWallet } from '@solana/wallet-adapter-react';
import dynamic from 'next/dynamic';
import { useState, useMemo } from 'react';
import { uploadJSONViaBundlr } from '@/utils/uploader';
import { sha256Hex } from '@/utils/hash';
import { transferBoos } from '@/utils/transferBoos';
const WalletMultiButton = dynamic(async () => (await import('@solana/wallet-adapter-react-ui')).WalletMultiButton, { ssr: false });
export default function Compose() {
  const { connection } = useConnection();
  const wallet = useWallet();
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [tags, setTags] = useState('');
  const [status, setStatus] = useState<string | null>(null);
  const [uri, setUri] = useState<string | null>(null);
  const [sig, setSig] = useState<string | null>(null);
  const boosFee = 50;
  const canInscribe = useMemo(() => Boolean(title.trim() && body.trim().length > 20 && wallet.connected), [title, body, wallet.connected]);
  async function handleInscribe() {
    try {
      if (!wallet.connected) { setStatus('Connect your wallet first.'); return; }
      setStatus('hashing');
      const story = { title: title.trim(), body: body.trim(), tags: tags.split(',').map(t=>t.trim()).filter(Boolean), author: wallet.publicKey?.toBase58() || null, ts: Date.now(), app: "BookOfSolana" };
      const h = await sha256Hex(JSON.stringify(story));
      setStatus('uploading to Arweave');
      // @ts-ignore
      const provider = wallet.adapter;
      const u = await uploadJSONViaBundlr({ ...story, sha256: h }, provider);
      setUri(u);
      setStatus('sending 50 BOOS fee');
      const signature = await transferBoos(connection, wallet, boosFee);
      setSig(signature);
      setStatus('done');
    } catch (e:any) { setStatus(e.message || 'Something went wrong'); }
  }
  return (
    <div className="grid gap-10">
      <section className="relative overflow-hidden rounded-3xl border border-neutral-800 bg-black/40">
        <div className="absolute inset-0 opacity-70 blur-2xl" style={{backgroundImage:'radial-gradient(400px 200px at 70% 0%, rgba(0,211,255,.25), transparent), radial-gradient(400px 200px at 30% 0%, rgba(153,69,255,.25), transparent)'}}/>
        <div className="relative px-6 py-10 md:px-10 flex items-center gap-6">
          <img src="/logo-book.svg" className="w-16 h-16 drop-shadow-glow" alt="Open Book"/>
          <div>
            <h1 className="text-3xl md:text-4xl font-semibold leading-tight">Open the Book. Inscribe your story.</h1>
            <p className="text-neutral-300 mt-2">Permanent words. Paid in BOOS. Welcome to the Book of Solana.</p>
          </div>
          <div className="ml-auto"><WalletMultiButton className="btn" /></div>
        </div>
      </section>
      <div className="card grid gap-4">
        <input className="input text-lg font-medium" placeholder="Title" value={title} onChange={e=>setTitle(e.target.value)} />
        <textarea className="input min-h-[220px]" placeholder="Write your story…" value={body} onChange={e=>setBody(e.target.value)} />
        <input className="input" placeholder="Tags (comma separated)" value={tags} onChange={e=>setTags(e.target.value)} />
        <div className="flex items-center gap-3">
          <button onClick={handleInscribe} disabled={!canInscribe} className="btn disabled:opacity-40">Inscribe (50 BOOS)</button>
          {status && <span className="text-sm text-neutral-400">{status}</span>}
        </div>
        {uri && (<div className="text-sm text-neutral-300">
          <div>Arweave: <a className="underline" href={uri} target="_blank" rel="noreferrer">{uri}</a></div>
          {sig && <div>Fee Tx: <a className="underline" href={`https://solscan.io/tx/${sig}`} target="_blank" rel="noreferrer">{sig}</a></div>}
        </div>)}
      </div>
    </div>
  )
}
TSX

cat > pages/feed.tsx <<'TSX'
import { useEffect, useState } from 'react';
type Item = { id: string; title: string; body: string; author: string | null; tags: string[]; ts: number; uri: string; };
export default function Feed() {
  const [items, setItems] = useState<Item[]>([]);
  const [q, setQ] = useState(''); const [loading, setLoading] = useState(false);
  async function fetchFeed() {
    setLoading(true);
    try {
      const query = { query: `{ transactions(tags:[{name:"App-Name",values:["BookOfSolana"]},{name:"Content-Type",values:["application/json"]}], first:25, sort:HEIGHT_DESC){ edges{node{id}} } }` };
      const res = await fetch("https://arweave.net/graphql", { method:"POST", headers:{ "Content-Type":"application/json" }, body: JSON.stringify(query)});
      const json = await res.json();
      const ids = (json?.data?.transactions?.edges || []).map((e:any)=>e.node.id);
      const entries: Item[] = [];
      for (const id of ids) {
        const uri = `https://arweave.net/${id}`;
        try { const r = await fetch(uri); const data = await r.json();
          entries.push({ id, title: data.title, body: data.body, author: data.author || null, tags: data.tags || [], ts: data.ts || 0, uri });
        } catch {}
      }
      entries.sort((a,b)=>(b.ts||0)-(a.ts||0)); setItems(entries);
    } finally { setLoading(false); }
  }
  useEffect(()=>{ fetchFeed(); }, []);
  const filtered = items.filter(i => (`${i.title} ${i.body} ${(i.tags||[]).join(' ')}`.toLowerCase().includes(q.toLowerCase())));
  return (
    <div className="grid gap-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold">The Book (latest inscriptions)</h1>
        <button className="btn" onClick={fetchFeed} disabled={loading}>{loading?'Refreshing...':'Refresh'}</button>
      </div>
      <input className="input" placeholder="Search title, body, tags..." value={q} onChange={e=>setQ(e.target.value)} />
      <div className="grid gap-3">
        {filtered.map(i=> (
          <article key={i.id} className="card">
            <div className="text-xs text-neutral-400 mb-2">{i.author ? `by ${i.author}` : 'by anonymous'} - {new Date(i.ts||0).toLocaleString()}</div>
            <h3 className="text-lg font-semibold mb-1">{i.title}</h3>
            <p className="text-neutral-200 whitespace-pre-wrap">{(i.body||'').slice(0,600)}</p>
            <div className="mt-3 flex flex-wrap gap-2">{i.tags?.map(t => <span key={t} className="tag">#{t}</span>)}</div>
            <div className="mt-3 text-sm"><a className="underline" href={i.uri} target="_blank" rel="noreferrer">Arweave</a></div>
          </article>
        ))}
        {!loading && filtered.length===0 && <div className="text-neutral-400">No inscriptions found yet.</div>}
      </div>
    </div>
  )
}
TSX

cat > README.md <<'MD'
# Book of Solana — Ethereal MVP (mainnet)
- Wallet connect (Phantom/Solflare/Backpack)
- Compose → Arweave (Bundlr) upload
- Fee: **50 BOOS** (decimals = 6) to treasury
- Feed with search

## Environment (Vercel)
- NEXT_PUBLIC_NETWORK = mainnet-beta
- NEXT_PUBLIC_TREASURY = Fo3ZwcugwUfn2Ye7MBdQyHjfqeeZ4nUrDRQ7oQ7MJsfd
- NEXT_PUBLIC_BOOS_MINT = GFJfGXKMZb9PWRMXWSb4WAkguiokknpu72v4KQwPmdqA
- NEXT_PUBLIC_BUNDLR_NODE = https://node1.bundlr.network
- NEXT_PUBLIC_BUNDLR_CURRENCY = solana

## Run locally
cp .env.example .env.local
npm i
npm run dev
MD

echo "📦 Installing deps…"
npm i --silent
echo "🛠 Build… (ok if it skips in Codespaces)"
npm run build --silent || true
echo "✅ Done. Start dev:  npm run dev"
