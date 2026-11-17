-- CP4 scalability experiment for the WhatsApp Messaging project.
-- Creates two isolated 5x benchmark copies; the production whatsapp.messages
-- table is not renamed, truncated, altered, or dropped.
-- Partition strategy: HASH(message_id), preserving a globally unique
-- message_id primary key and compatibility with message_id-based references.

SET search_path TO whatsapp;

DROP TABLE IF EXISTS whatsapp.messages_hash_partitioned CASCADE;
DROP TABLE IF EXISTS whatsapp.messages_unpartitioned_large CASCADE;

-- A non-partitioned control copy with the same schema/check constraints.
CREATE TABLE whatsapp.messages_unpartitioned_large
  (LIKE whatsapp.messages INCLUDING DEFAULTS INCLUDING CONSTRAINTS);
ALTER TABLE whatsapp.messages_unpartitioned_large
  ADD CONSTRAINT messages_unpartitioned_large_pkey PRIMARY KEY (message_id);

-- Eight hash partitions. The partition key is also the primary key, so
-- PostgreSQL can enforce uniqueness across the partitioned relation.
CREATE TABLE whatsapp.messages_hash_partitioned
  (LIKE whatsapp.messages INCLUDING DEFAULTS INCLUDING CONSTRAINTS)
  PARTITION BY HASH (message_id);
ALTER TABLE whatsapp.messages_hash_partitioned
  ADD CONSTRAINT messages_hash_partitioned_pkey PRIMARY KEY (message_id);

CREATE TABLE whatsapp.messages_hash_partitioned_p0 PARTITION OF whatsapp.messages_hash_partitioned
  FOR VALUES WITH (MODULUS 8, REMAINDER 0);
CREATE TABLE whatsapp.messages_hash_partitioned_p1 PARTITION OF whatsapp.messages_hash_partitioned
  FOR VALUES WITH (MODULUS 8, REMAINDER 1);
CREATE TABLE whatsapp.messages_hash_partitioned_p2 PARTITION OF whatsapp.messages_hash_partitioned
  FOR VALUES WITH (MODULUS 8, REMAINDER 2);
CREATE TABLE whatsapp.messages_hash_partitioned_p3 PARTITION OF whatsapp.messages_hash_partitioned
  FOR VALUES WITH (MODULUS 8, REMAINDER 3);
CREATE TABLE whatsapp.messages_hash_partitioned_p4 PARTITION OF whatsapp.messages_hash_partitioned
  FOR VALUES WITH (MODULUS 8, REMAINDER 4);
CREATE TABLE whatsapp.messages_hash_partitioned_p5 PARTITION OF whatsapp.messages_hash_partitioned
  FOR VALUES WITH (MODULUS 8, REMAINDER 5);
CREATE TABLE whatsapp.messages_hash_partitioned_p6 PARTITION OF whatsapp.messages_hash_partitioned
  FOR VALUES WITH (MODULUS 8, REMAINDER 6);
CREATE TABLE whatsapp.messages_hash_partitioned_p7 PARTITION OF whatsapp.messages_hash_partitioned
  FOR VALUES WITH (MODULUS 8, REMAINDER 7);

-- Matching indexes on control and partitioned relations.
CREATE INDEX idx_messages_large_chat_sent ON whatsapp.messages_unpartitioned_large (chat_id, sent_at DESC);
CREATE INDEX idx_messages_large_sent ON whatsapp.messages_unpartitioned_large (sent_at);
CREATE INDEX idx_messages_large_reply ON whatsapp.messages_unpartitioned_large (reply_to_message_id);
CREATE INDEX idx_messages_hash_chat_sent ON whatsapp.messages_hash_partitioned (chat_id, sent_at DESC);
CREATE INDEX idx_messages_hash_sent ON whatsapp.messages_hash_partitioned (sent_at);
CREATE INDEX idx_messages_hash_reply ON whatsapp.messages_hash_partitioned (reply_to_message_id);

-- Load original 1x data plus four deterministic replicas (5x total).
-- Replicas use disjoint message_id ranges and remap internal reply pointers.
INSERT INTO whatsapp.messages_unpartitioned_large
  (message_id, chat_id, sender_id, sent_at, message_type, body, media_id,
   reply_to_message_id, is_forwarded, is_deleted, edited_at)
SELECT m.message_id, m.chat_id, m.sender_id, m.sent_at, m.message_type,
       m.body, m.media_id, m.reply_to_message_id, m.is_forwarded,
       m.is_deleted, m.edited_at
FROM whatsapp.messages AS m;

INSERT INTO whatsapp.messages_hash_partitioned
  (message_id, chat_id, sender_id, sent_at, message_type, body, media_id,
   reply_to_message_id, is_forwarded, is_deleted, edited_at)
SELECT m.message_id, m.chat_id, m.sender_id, m.sent_at, m.message_type,
       m.body, m.media_id, m.reply_to_message_id, m.is_forwarded,
       m.is_deleted, m.edited_at
FROM whatsapp.messages AS m;

DO $$
DECLARE
  v_max_id BIGINT;
BEGIN
  SELECT COALESCE(MAX(message_id), 0) INTO v_max_id FROM whatsapp.messages;
  FOR replica IN 1..4 LOOP
    INSERT INTO whatsapp.messages_unpartitioned_large
      (message_id, chat_id, sender_id, sent_at, message_type, body, media_id,
       reply_to_message_id, is_forwarded, is_deleted, edited_at)
    SELECT m.message_id + v_max_id * replica,
           m.chat_id, m.sender_id,
           m.sent_at + make_interval(months => replica),
           m.message_type, m.body, m.media_id,
           CASE WHEN m.reply_to_message_id IS NULL THEN NULL
                ELSE m.reply_to_message_id + v_max_id * replica END,
           m.is_forwarded, m.is_deleted,
           CASE WHEN m.edited_at IS NULL THEN NULL
                ELSE m.edited_at + make_interval(months => replica) END
    FROM whatsapp.messages AS m;

    INSERT INTO whatsapp.messages_hash_partitioned
      (message_id, chat_id, sender_id, sent_at, message_type, body, media_id,
       reply_to_message_id, is_forwarded, is_deleted, edited_at)
    SELECT m.message_id + v_max_id * replica,
           m.chat_id, m.sender_id,
           m.sent_at + make_interval(months => replica),
           m.message_type, m.body, m.media_id,
           CASE WHEN m.reply_to_message_id IS NULL THEN NULL
                ELSE m.reply_to_message_id + v_max_id * replica END,
           m.is_forwarded, m.is_deleted,
           CASE WHEN m.edited_at IS NULL THEN NULL
                ELSE m.edited_at + make_interval(months => replica) END
    FROM whatsapp.messages AS m;
  END LOOP;
END $$;

-- Restore relevant referential constraints on both benchmark copies.
ALTER TABLE whatsapp.messages_unpartitioned_large
  ADD CONSTRAINT messages_large_chat_fk FOREIGN KEY (chat_id) REFERENCES whatsapp.chats(chat_id),
  ADD CONSTRAINT messages_large_sender_fk FOREIGN KEY (sender_id) REFERENCES whatsapp.users(user_id),
  ADD CONSTRAINT messages_large_media_fk FOREIGN KEY (media_id) REFERENCES whatsapp.media(media_id),
  ADD CONSTRAINT messages_large_reply_fk FOREIGN KEY (reply_to_message_id) REFERENCES whatsapp.messages_unpartitioned_large(message_id);

ALTER TABLE whatsapp.messages_hash_partitioned
  ADD CONSTRAINT messages_hash_chat_fk FOREIGN KEY (chat_id) REFERENCES whatsapp.chats(chat_id),
  ADD CONSTRAINT messages_hash_sender_fk FOREIGN KEY (sender_id) REFERENCES whatsapp.users(user_id),
  ADD CONSTRAINT messages_hash_media_fk FOREIGN KEY (media_id) REFERENCES whatsapp.media(media_id),
  ADD CONSTRAINT messages_hash_reply_fk FOREIGN KEY (reply_to_message_id) REFERENCES whatsapp.messages_hash_partitioned(message_id);

ANALYZE whatsapp.messages_unpartitioned_large;
ANALYZE whatsapp.messages_hash_partitioned;

-- Expected row counts: control and partitioned copies must match.
SELECT 'unpartitioned' AS storage, COUNT(*) AS rows FROM whatsapp.messages_unpartitioned_large
UNION ALL
SELECT 'hash_partitioned', COUNT(*) FROM whatsapp.messages_hash_partitioned;

SELECT tableoid::regclass AS partition_name, COUNT(*) AS rows
FROM whatsapp.messages_hash_partitioned
GROUP BY tableoid
ORDER BY partition_name;

SELECT pg_size_pretty(pg_total_relation_size('whatsapp.messages_unpartitioned_large')) AS unpartitioned_size,
       pg_size_pretty(pg_total_relation_size('whatsapp.messages_hash_partitioned')) AS partitioned_size;

-- File use case: compare isolated 5x unpartitioned and HASH(message_id)
-- benchmark copies without changing whatsapp.messages. The replica loop
-- offsets IDs/reply pointers and shifts timestamps; p0-p7 are the eight
-- hash partitions whose row counts and relation sizes are reported above.
