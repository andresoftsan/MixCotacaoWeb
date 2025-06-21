// Configuração de produção para PM2
module.exports = {
  apps: [{
    name: 'mix-cotacao-web',
    script: 'dist/index.js',
    cwd: process.cwd(),
    env_file: '.env',
    env: {
      NODE_ENV: 'production',
      PORT: 5000
    },
    instances: 1,
    exec_mode: 'fork',
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    
    // Logs
    log_file: './logs/combined.log',
    out_file: './logs/out.log',
    error_file: './logs/error.log',
    time: true,
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    
    // Restart delay
    min_uptime: '10s',
    max_restarts: 10,
    restart_delay: 4000
  }]
};