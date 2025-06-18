// Configuração de produção para PM2
module.exports = {
  apps: [{
    name: 'mix-cotacao-web',
    script: 'npm',
    args: 'start',
    cwd: process.cwd(),
    env: {
      NODE_ENV: 'production',
      PORT: 5000
    },
    instances: 1,
    exec_mode: 'fork',
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    node_args: '--max-old-space-size=1024',
    
    // Logs
    log_file: './logs/combined.log',
    out_file: './logs/out.log',
    error_file: './logs/error.log',
    time: true,
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    
    // Restart delay
    min_uptime: '10s',
    max_restarts: 10,
    restart_delay: 4000,
    
    // Health check
    health_check_grace_period: 3000,
    
    // Environment variables for production
    env_production: {
      NODE_ENV: 'production',
      PORT: 5000,
      // Database URL será definida no .env
      // SESSION_SECRET será definida no .env
    }
  }]
};