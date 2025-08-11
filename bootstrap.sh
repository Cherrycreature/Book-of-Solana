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
