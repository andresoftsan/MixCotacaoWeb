# Mix Cotação Web - Replit Configuration

## Overview

Mix Cotação Web is a comprehensive quotation management system built with React frontend and Express.js backend. The application provides a complete solution for managing sellers, quotations, and quotation items with role-based access control.

## System Architecture

### Frontend Architecture
- **Framework**: React 18 with TypeScript
- **Routing**: Wouter for client-side routing
- **State Management**: TanStack Query (React Query) for server state
- **UI Components**: Radix UI with Tailwind CSS
- **Forms**: React Hook Form with Zod validation
- **Toast Notifications**: Custom toast system with Radix UI

### Backend Architecture
- **Runtime**: Node.js with Express.js
- **Language**: TypeScript with ES modules
- **Authentication**: Session-based auth with express-session
- **API Authentication**: Bearer token support for external integrations
- **Password Hashing**: bcrypt for secure password storage
- **Database ORM**: Drizzle ORM with PostgreSQL

### Database Schema
- **sellers**: User management with role-based access (admin/seller)
- **quotations**: Main quotation entities with status tracking
- **quotation_items**: Individual items within quotations
- **api_keys**: API token management for external integrations

## Key Components

### Authentication System
- **Session-based**: Web interface uses cookie sessions
- **Token-based**: API endpoints support Bearer tokens
- **Flexible middleware**: Supports both authentication methods
- **Role separation**: Admin vs seller permissions

### Business Logic
- **Quotation Management**: Create, edit, and track quotations
- **Status Workflow**: Automatic status updates based on deadlines
- **Search Functionality**: Advanced search by email, name, CNPJ, and quotation number
- **Item Management**: Detailed product information with pricing and availability

### API Design
- **RESTful endpoints**: Standard HTTP methods and status codes
- **Consistent responses**: JSON format with error handling
- **Query parameters**: Support for filtering and searching
- **Pagination**: Built-in pagination for large datasets

## Data Flow

### Authentication Flow
1. User logs in via `/api/auth/login`
2. Session created and stored in database
3. Subsequent requests authenticated via session cookies
4. API requests can use Bearer tokens for external integration

### Quotation Management Flow
1. Sellers create quotations with basic information
2. Items added to quotations with product details
3. Status automatically updated based on deadline
4. Admins have full access, sellers see only their quotations

### Search and Filtering
1. Frontend sends search parameters to API
2. Database queries use LIKE operations for flexible matching
3. Results filtered based on user permissions
4. Pagination applied to manage large result sets

## External Dependencies

### Frontend Dependencies
- React ecosystem (React, React DOM, React Query)
- UI libraries (Radix UI components, Tailwind CSS)
- Form handling (React Hook Form, Zod)
- Routing (Wouter)
- Date utilities (date-fns)

### Backend Dependencies
- Express.js with TypeScript support
- Database (Drizzle ORM, @neondatabase/serverless)
- Authentication (bcrypt, express-session, connect-pg-simple)
- Development tools (tsx, esbuild)

### Development Tools
- Vite for frontend build system
- TypeScript for type safety
- Tailwind CSS for styling
- Drizzle Kit for database migrations

## Deployment Strategy

### Local Development
- Uses Vite dev server with hot module replacement
- Database connections via environment variables
- Session storage in PostgreSQL
- Concurrent frontend/backend development

### Production Build
- Frontend: Vite builds optimized static assets
- Backend: esbuild creates single Node.js bundle
- Static files served by Express in production
- Database migrations handled by Drizzle Kit

### Environment Configuration
- `DATABASE_URL`: PostgreSQL connection string
- `SESSION_SECRET`: Session encryption key
- `NODE_ENV`: Environment mode (development/production)
- `PORT`: Application port (default 5000)

### Database Setup
- Automatic admin user creation on first startup
- Database schema managed through Drizzle migrations
- Support for external PostgreSQL databases
- Comprehensive setup scripts provided

## Deployment Configuration

### AWS Lightsail Production Setup
The application is configured for deployment on AWS Lightsail Ubuntu 24.04 with:
- PostgreSQL database on the same instance
- Nginx as reverse proxy
- PM2 for process management
- SSL support via Certbot
- Automated backup and monitoring scripts

### Deployment Files
- `AWS_LIGHTSAIL_DEPLOY_GUIDE.md`: Complete deployment tutorial
- `install-lightsail.sh`: Automated installation script
- `production.config.js`: PM2 production configuration

### Key Features for Production
- Automatic database migrations via `npm run db:push`
- Health checks and auto-restart capabilities
- Log rotation and backup scheduling
- Firewall and security configurations
- SSL certificate management

## API Integration

### Token Authentication
The system supports API token authentication for external integrations:
- Bearer token format: `Authorization: Bearer [token]`
- Tokens managed per seller in the database
- Full CRUD operations available via API endpoints

### Fixed Issues
- Quotation numbering: Resolved duplicate number generation by implementing proper sequential numbering
- API authentication: Confirmed working with proper Bearer token headers
- Database connectivity: Stable connection with comprehensive error logging
- AWS Production SSL Certificate Error: Created troubleshooting scripts and guides for DATABASE_URL configuration conflicts
- AWS PostgreSQL Driver: Migrated from Neon serverless driver to standard pg driver for local PostgreSQL compatibility
- ESM Module Resolution: Fixed Node.js ES modules import errors in production build
- Environment Variables: Configured dotenv loading and PM2 env_file support for production

## Changelog
- June 17, 2025: Initial setup and core functionality
- June 17, 2025: Fixed API quotation creation and numbering system
- June 17, 2025: Added comprehensive AWS Lightsail deployment configuration
- June 21, 2025: Fixed PostgreSQL driver (Neon to pg), resolved API token authentication, complete AWS EC2 deployment setup

## User Preferences

Preferred communication style: Simple, everyday language.

## Recent Changes (July 1, 2025)

✅ **Bloqueio de Edição para Status "Prazo Encerrado"**
- Implementado bloqueio de edição de itens quando cotação tem status "Prazo Encerrado"
- Atualizada página de edição de cotação (quotation-edit.tsx)
- Atualizado modal de detalhes da cotação (quotation-detail-modal.tsx)
- Comportamento agora idêntico ao status "Enviada" - sem possibilidade de edição
- Campos bloqueados: quantidade disponível, preço unitário, validade, situação
- Botões de ação (Salvar/Enviar) também bloqueados para status expirado