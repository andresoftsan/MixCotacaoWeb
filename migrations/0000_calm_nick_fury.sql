CREATE TABLE "quotation_items" (
	"id" serial PRIMARY KEY NOT NULL,
	"quotation_id" integer NOT NULL,
	"barcode" text NOT NULL,
	"product_name" text NOT NULL,
	"quoted_quantity" integer NOT NULL,
	"available_quantity" integer,
	"unit_price" numeric(10, 2),
	"validity" timestamp,
	"situation" text
);
--> statement-breakpoint
CREATE TABLE "quotations" (
	"id" serial PRIMARY KEY NOT NULL,
	"number" text NOT NULL,
	"date" timestamp DEFAULT now() NOT NULL,
	"status" text DEFAULT 'Aguardando digitação' NOT NULL,
	"deadline" timestamp NOT NULL,
	"supplier_cnpj" text NOT NULL,
	"supplier_name" text NOT NULL,
	"client_cnpj" text NOT NULL,
	"client_name" text NOT NULL,
	"internal_observation" text,
	"seller_id" integer NOT NULL,
	"created_at" timestamp DEFAULT now(),
	CONSTRAINT "quotations_number_unique" UNIQUE("number")
);
--> statement-breakpoint
CREATE TABLE "sellers" (
	"id" serial PRIMARY KEY NOT NULL,
	"email" text NOT NULL,
	"name" text NOT NULL,
	"password" text NOT NULL,
	"status" text DEFAULT 'Ativo' NOT NULL,
	"created_at" timestamp DEFAULT now(),
	CONSTRAINT "sellers_email_unique" UNIQUE("email")
);
--> statement-breakpoint
ALTER TABLE "quotation_items" ADD CONSTRAINT "quotation_items_quotation_id_quotations_id_fk" FOREIGN KEY ("quotation_id") REFERENCES "public"."quotations"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "quotations" ADD CONSTRAINT "quotations_seller_id_sellers_id_fk" FOREIGN KEY ("seller_id") REFERENCES "public"."sellers"("id") ON DELETE no action ON UPDATE no action;