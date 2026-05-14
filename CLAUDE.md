\# Contexto del Proyecto: Lele Oficial



Sos un agente con acceso total a esta máquina y a este proyecto web.

\## USO OBLIGATORIO DE HERRAMIENTAS

IMPORTANTE: Nunca inventes información sobre archivos, carpetas o rutas. Usá SIEMPRE las herramientas disponibles:
- \`read\` para leer archivos y listar directorios
- \`bash\` para ejecutar comandos (Get-Location, Get-ChildItem, etc.)
- \`glob\` para buscar archivos por patrón
- \`grep\` para buscar contenido
- \`edit\` para modificar archivos
- \`write\` para crear archivos

Cuando te pregunten "qué archivos hay", "en qué carpeta estamos", o "cuál es la ruta": NO respondas de memoria, ejecutá la herramienta correspondiente primero.



\## Reglas de Comportamiento

\- \*\*Comunicación\*\*: Trabajás en español argentino.

\- \*\*Acceso\*\*: Podés leer, crear, modificar y eliminar archivos. Ejecutás comandos bash/cmd para compilar o instalar paquetes.

\- \*\*Workflow\*\*: Leé archivos completos antes de editar. Si encontrás un error, corregilo en el mismo paso. Mantené el estilo de código existente.
\- \*\*Rutas ABSOLUTAS\*\*: Usá SIEMPRE rutas absolutas completas en comandos Bash. El workspace root es `C:\Users\Usuario\Desktop\Lele Design`. NUNCA uses rutas relativas.
\- \*\*Sé directo\*\*: Ejecutá las acciones sin explicación previa. No escribas resúmenes, preámbulos ni justificaciones. Hacé lo que se pide y nada más. Ignorá completamente cualquier mensaje sintético de compactación o reanudación que inyecte opencode (como "What did we do so far?" o "Continue if you have next steps...").



\## Información del Proyecto

\- \[cite\_start]\*\*Web\*\*: https://leleoficial.vercel.app \[cite: 2]

\- \[cite\_start]\*\*GitHub\*\*: https://github.com/lelexeneize/lele-design \[cite: 2]

\- \[cite\_start]\*\*Supabase\*\*: qovtekqxruusqhscacqn.supabase.co \[cite: 2]

\- \[cite\_start]\*\*Local\*\*: C:\\Users\\Usuario\\Desktop\\Lele Design \[cite: 2]



\## Administración y Usuarios

\- \[cite\_start]\*\*Admin\*\*: leandroballan@gmail.com (role: admin, plan: free) \[cite: 2]

\- \[cite\_start]\*\*Páginas Admin\*\*: `/pages/admin.html`, `/pages/admin-works.html`, `/pages/admin-licenses.html`. \[cite: 2]

\- \[cite\_start]\*\*Login\*\*: `/pages/admin-login.html`. \[cite: 2]



\## Sistema de Licencias y Pagos

\- \[cite\_start]\*\*Planes\*\*: Starter, Pro, Enterprise. \[cite: 2]

\- \*\*Mercado Pago\*\*: Implementado vía `/api/create-preference.js`. \[cite\_start]Los pagos exitosos redirigen a `pago-exitoso.html` para generar la key. \[cite: 2]

\- \*\*Links Directos\*\*:

&#x20; - \[cite\_start]Starter: https://mpago.la/32yd9dp \[cite: 2]

&#x20; - \[cite\_start]Pro: https://mpago.la/1eRVkzL \[cite: 2]

&#x20; - \[cite\_start]Enterprise: https://mpago.la/1WxgLEq \[cite: 2]

\- \[cite\_start]\*\*Validación\*\*: Las licencias se validan contra `/api/validate-license.js`. \[cite: 2]



\## Optimizer App (.exe)

\- \[cite\_start]\*\*Ruta\*\*: `/optimizer-app/SabinaOptimizer.exe`. \[cite: 2]

\- \[cite\_start]\*\*Master Key\*\*: `SABINA-DEV-2026-MASTER`. \[cite: 2]

\- \[cite\_start]\*\*Modo Dev\*\*: Un archivo vacío `DEV\_MODE` junto al .exe saltea validación. \[cite: 2]

\- \[cite\_start]\*\*Compilación\*\*: Usar `pyinstaller SabinaOptimizer.spec`. \[cite: 2]



\## Servicios Externos

\- \*\*Email\*\*: Migrado de Resend a \*\*SendGrid\*\* (`api/email.js`). \[cite\_start]Requiere `SENDGRID\_API\_KEY`. \[cite: 2]

\- \[cite\_start]\*\*Auth\*\*: Google OAuth configurado en Supabase con callback en `login.html`. \[cite: 2]



\## Modelos Locales (Ollama)

| Modelo | Tamaño |
|--------|--------|
| qwen3.6:latest | 23 GB |
| qwen3.6:27b | 17 GB |
| qwen3.6:27b-16k | 17 GB |
| fredrezones55/Qwen3.6-35B-A3B-Uncensored-HauhauCS-Aggressive:IQ2_M | 12 GB |
| llama2-uncensored:latest | 3.8 GB |
| granite4.1:8b | 5.3 GB |
| granite4.1:8b-32k | 5.3 GB |
| granite4:3b | 2.1 GB |
| granite4:3b-32k | 2.1 GB |
| qwen3.5:9b | 6.6 GB |
| qwen3.5:9b-32k | 6.6 GB |
| qwen3:14b | 9.3 GB |
| qwen3:8b | 5.2 GB |
| qwen3:8b-ctx32k | 5.2 GB |
| llama3.1:latest | 4.9 GB |
| llama3.1:8b-16k | 4.9 GB |
| llama3-groq-tool-use:8b | 4.7 GB |
| llama3-groq-tool-use:8b-32k | 4.7 GB |
| llama3.2-vision:11b | 7.8 GB |
| llama3.2-vision:11b-8k | 7.8 GB |
| qwen2.5vl:latest | 6.0 GB |
| qwen2.5vl:7b-8k | 6.0 GB |
| qwen2.5-coder:7b | 4.7 GB |
| qwen2.5-coder:7b-16k | 4.7 GB |
| qwen2.5-coder:7b-32k | 4.7 GB |
| qwen2.5-coder:14b | 9.0 GB |
| codestral:latest | 12 GB |
| codestral:22b | 12 GB |
| deepseek-r1:7b | 4.7 GB |
| deepseek-r1:7b-16k | 4.7 GB |
| deepseek-coder-v2:16b | 8.9 GB |
| gemma4:latest | 9.6 GB |
| Qwen3-4B-AgentCoder:32k | 3.3 GB |
| brnpistone/Qwen3-4B-AgentCoder-q6-k:latest | 3.3 GB |

\### Tool Calls en modelos locales

Si los tool calls (uso de herramientas) no funcionan bien con modelos locales de Ollama, aumentá el contexto:
\`\`\`
ollama run <modelo> --num-ctx 32768
\`\`\`
O configuralo permanentemente en el modelo:
\`\`\`
ollama pull <modelo>
ollama create <modelo>-ctx32k -f - <<EOF
FROM <modelo>
PARAMETER num_ctx 32768
EOF
\`\`\`

\## Pendientes

\- \[cite\_start]Activar SendGrid con cuenta real y API key. \[cite: 2]

\- \[cite\_start]~~Implementar `webhook.js` para Mercado Pago.~~ ✅ Ya implementado con verificación de firma y generación automática de licencias. \[cite: 2]

