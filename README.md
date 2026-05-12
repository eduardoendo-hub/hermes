# Hermes

Tela de atendimento WhatsApp da **Tech Now**, construída como whitelabel do Chatwoot e deployada via **Coolify**.

- **Domínio:** https://hermes.technowhub.ai
- **Stack:** Chatwoot v3.16 + Postgres15 + Redis7 + Sidekiq
- **Orquestração:** Coolify (Traefik + Let's Encrypt automático)
- **Canal V1:** WhatsApp Cloud API (Meta oficial)

---

## Layout do repo

```
Hermes/
├── coolify/
│   ├── chatwoot-stack.yml   # docker-compose pra colar no Coolify
│   ├── env-vars.md          # referência das envs (magic vars do Coolify)
│   └── setup-guide.md       # passo a passo UI Coolify (10 passos)
├── branding/                # identidade Hermes / Tech Now
│   ├── logo.svg             # wordmark claro
│   ├── logo-dark.svg        # wordmark escuro
│   ├── logo-thumbnail.svg   # só o mark
│   ├── favicon.svg
│   └── custom.css           # override Tiffany/Rose pra colar em Chatwoot
├── scripts/
│   └── sync-branding.sh     # rsync + docker cp dos logos no volume
├── README.md                # este arquivo
└── .gitignore
```

---

## Quickstart (10 min, assumindo Coolify rodando)

1. **DNS** — crie `A hermes.technowhub.ai → <IP do server Coolify>` (TTL 60).
2. **Coolify UI** → Projects → **New Project** "Hermes" → selecione o server.
3. **+ New Resource** → **Docker Compose Empty** → cole `coolify/chatwoot-stack.yml`.
4. **Domains for rails** → `https://hermes.technowhub.ai` → save.
5. **Deploy**. Aguarde ~3min até rails e sidekiq ficarem `healthy`.
6. **Terminal** no container `rails` → `bundle exec rails db:chatwoot_prepare` → restart.
7. Abrir `https://hermes.technowhub.ai` → primeiro signup = super admin.
8. **Sync branding** (laptop):
   ```bash
   ./scripts/sync-branding.sh <usuario>@<coolify-server>
   ```
9. **Custom CSS** no UI Chatwoot (Settings → Custom CSS) → colar `branding/custom.css`.
10. **WhatsApp Cloud**: Settings → Inboxes → Add → WhatsApp Cloud. Detalhes em [`coolify/setup-guide.md`](coolify/setup-guide.md).

Passos detalhados (com troubleshooting) em [`coolify/setup-guide.md`](coolify/setup-guide.md).

---

## Operação

### Logs

Coolify UI → resource `chatwoot` → **Logs** → escolha o container (`rails`, `sidekiq`, `postgres`, `redis`).

Ou via SSH no host Coolify:

```bash
docker logs -f --tail 100 <container_id>
```

### Restart parcial

Coolify UI → resource `chatwoot` → **Restart**. Para uma única service, use Terminal pra `kill -HUP` ou redeploy via UI.

### Atualizar Chatwoot

1. Edite `coolify/chatwoot-stack.yml` → bump `chatwoot/chatwoot:v3.16.0` pra nova tag.
2. Cole no Coolify (sobrescreve) → **Deploy**.
3. Após subir, abra terminal no `rails`:
   ```bash
   bundle exec rails db:migrate
   ```

### Backup manual do Postgres

Via Coolify UI → resource → **Backups** (built-in agendado), ou ad-hoc:

```bash
# SSH no host Coolify:
docker exec <postgres-container> pg_dump -U chatwoot chatwoot | gzip > hermes-$(date +%Y%m%d).sql.gz
```

---

## Branding

Logos em [`branding/`](branding/) — 4 SVGs (claro, escuro, thumb, favicon) + 1 CSS:

- **Mark**: asa estilizada em gradiente `#057572 → #0ABAB5 → #81D8D0` + ponto Rose `#EC6088`
- **Wordmark**: "Hermes" em Inter Black 900, letter-spacing `-0.04em`
- **Custom CSS**: aplica Tiffany como `--color-woot` e Rose como accent badge

Trocar logo:
1. Substitua os SVGs em `branding/`
2. `./scripts/sync-branding.sh <ssh-target>`
3. Restart `rails` + `sidekiq` no Coolify

---

## Roadmap (V2+)

- [ ] SMTP transacional (Mailgun ou SES) — pra invites/password reset
- [ ] Backup automático diário (Coolify Backups → S3/B2)
- [ ] Monitoring (Uptime Kuma + Grafana)
- [ ] WhatsApp Business Verification (sair do test mode da Meta)
- [ ] Templates de mensagem aprovados
- [ ] SSO via Google Workspace
- [ ] Múltiplos números / inboxes
- [ ] Logo definitivo da Hermes (iterar com design)
- [ ] CI: GitHub Actions → Coolify webhook (auto-deploy ao mergear em main)

---

## Segurança

- Nenhum segredo no repo. Coolify gera `SERVICE_PASSWORD_*` e `SERVICE_BASE64_64_SECRETKEYBASE` automaticamente.
- `.gitignore` cobre `.env`, `*.pem`, tokens.
- Coolify Traefik adiciona HSTS quando você marca "Force HTTPS" na resource.
- WhatsApp tokens só na UI do Chatwoot (Settings → Inboxes), nunca no compose.
