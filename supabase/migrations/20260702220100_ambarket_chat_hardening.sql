-- Allow users to update is_read status for messages they receive
CREATE POLICY "Users can update their received messages" 
ON public.messages FOR UPDATE 
USING (auth.uid() = receiver_id);
