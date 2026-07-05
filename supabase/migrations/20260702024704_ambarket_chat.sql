-- Create conversations table
CREATE TABLE public.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
    buyer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    seller_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    offer_id UUID REFERENCES public.offers(id) ON DELETE SET NULL,
    last_message TEXT,
    last_message_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE(product_id, buyer_id, seller_id)
);

-- Create messages table
CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE NOT NULL,
    sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    receiver_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Enable RLS
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Setup updated_at trigger for conversations
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.conversations 
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Policies for conversations
-- Users can view conversations if they are buyer or seller
CREATE POLICY "Users can view their own conversations" 
ON public.conversations FOR SELECT 
USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

-- Users can insert conversations if they are participants
CREATE POLICY "Users can insert conversations" 
ON public.conversations FOR INSERT 
WITH CHECK (auth.uid() = buyer_id OR auth.uid() = seller_id);

-- Only allow update if participant (for last message trigger)
CREATE POLICY "Users can update their conversations" 
ON public.conversations FOR UPDATE 
USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

-- Policies for messages
-- Users can view messages of their conversations
CREATE POLICY "Users can view messages of their conversations" 
ON public.messages FOR SELECT 
USING (
  EXISTS (
    SELECT 1 FROM public.conversations c 
    WHERE c.id = conversation_id 
    AND (c.buyer_id = auth.uid() OR c.seller_id = auth.uid())
  )
);

-- Users can insert messages if they are the sender and part of the conversation
CREATE POLICY "Users can insert messages" 
ON public.messages FOR INSERT 
WITH CHECK (
  auth.uid() = sender_id AND
  EXISTS (
    SELECT 1 FROM public.conversations c 
    WHERE c.id = conversation_id 
    AND (c.buyer_id = auth.uid() OR c.seller_id = auth.uid())
    AND (c.buyer_id = receiver_id OR c.seller_id = receiver_id)
  )
);

-- Function to update conversation last_message on new message
CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.conversations
  SET last_message = NEW.message,
      last_message_at = NEW.created_at,
      updated_at = now()
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_message_created
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE PROCEDURE update_conversation_last_message();
