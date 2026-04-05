-- Orders Table Definition
-- جدول الطلبات
create table public.orders (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) not null,
  
  -- Financial Info
  total_amount decimal(10, 2) not null,
  payment_method text not null, -- 'card', 'apple_pay', 'mada', 'cash'
  status text default 'pending' check (status in ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
  
  -- Shipping/Contact Info (Top Level for easy access)
  phone text not null,
  city text not null,
  address text not null,
  
  -- Structured Data (Optional but recommended for flexibility)
  shipping_address jsonb, -- Full address object
  metadata jsonb, -- Any extra data
  
  -- Timestamps
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.orders enable row level security;

-- Policies
create policy "Users can view their own orders" 
on public.orders for select 
using (auth.uid() = user_id);

create policy "Users can insert their own orders" 
on public.orders for insert 
with check (auth.uid() = user_id);


-- Order Items Table Definition
-- جدول عناصر الطلب
create table public.order_items (
  id uuid default gen_random_uuid() primary key,
  order_id uuid references public.orders(id) on delete cascade not null,
  
  -- Product Links (Snapshot is better for history, but FK is good for integrity)
  product_id uuid references public.products(id),
  variant_id uuid references public.product_variants(id),
  
  -- Snapshot Data (In case product is changed/deleted later)
  name_ar text not null, 
  -- name_en text, -- Optional
  
  -- Quantity & Price
  qty integer not null,
  unit_price decimal(10, 2) not null,
  subtotal decimal(10, 2) not null,
  
  -- Specifics
  metadata jsonb -- Stores: weight, cutting_method, notes
);

-- Enable RLS
alter table public.order_items enable row level security;

-- Policies
create policy "Users can view their own order items" 
on public.order_items for select 
using (
  exists (
    select 1 from public.orders 
    where orders.id = order_items.order_id 
    and orders.user_id = auth.uid()
  )
);

create policy "Users can insert their own order items" 
on public.order_items for insert 
with check (
  exists (
    select 1 from public.orders 
    where orders.id = order_items.order_id 
    and orders.user_id = auth.uid()
  )
);
