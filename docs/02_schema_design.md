# Phase 2 – Schema Design and Normalization

## 1. Database Overview

The WhatsApp Messaging Database is designed in PostgreSQL using nine relational tables. The schema separates users, devices, chats, memberships, media, messages, receipts, calls and blocked-user relationships to reduce redundancy and maintain referential integrity.

The database uses the `whatsapp` schema.

The ER diagram is available at `diagrams/er_diagram.png` (PDF version: `diagrams/er_diagram.pdf`).

## 2. Relations and Candidate Keys

| Relation | Primary Key | Additional Candidate Key |
|---|---|---|
| users | user_id | phone_e164 |
| devices | device_id | — |
| chats | chat_id | — |
| chat_members | (chat_id, user_id) | — |
| media | media_id | — |
| messages | message_id | — |
| message_receipts | (message_id, user_id) | — |
| calls | call_id | — |
| blocked_users | (blocker_id, blocked_id) | — |

A dash indicates that no additional candidate key has been established from the supplied dataset and requirements.


## 3. Complete Data Dictionary

The following data dictionary is generated from the live PostgreSQL `whatsapp` schema. It records all columns, data types, nullability, key roles and foreign-key references.

| Table | Column | Data Type | Nullable | Key | References | Constraint | Purpose |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `blocked_users` | `blocker_id` | `bigint` | NO | PK | users.user_id | Composite PRIMARY KEY; FOREIGN KEY; self-blocking CHECK | User who initiated the block. |
| `blocked_users` | `blocked_id` | `bigint` | NO | PK | users.user_id | Composite PRIMARY KEY; FOREIGN KEY; self-blocking CHECK | User who was blocked. |
| `blocked_users` | `blocked_at` | `timestamp with time zone` | NO | — | — | NOT NULL | Timestamp when the block was created. |
| `calls` | `call_id` | `bigint` | NO | PK | — | PRIMARY KEY; positive-value CHECK | Unique identifier for a call. |
| `calls` | `chat_id` | `bigint` | NO | — | chats.chat_id | NOT NULL; FOREIGN KEY | Chat in which the call occurred. |
| `calls` | `caller_id` | `bigint` | NO | — | users.user_id | NOT NULL; FOREIGN KEY | User who initiated the call. |
| `calls` | `call_type` | `text` | NO | — | — | NOT NULL; allowed-value CHECK | Voice or video call category. |
| `calls` | `started_at` | `timestamp with time zone` | NO | — | — | NOT NULL | Call start timestamp. |
| `calls` | `answered_at` | `timestamp with time zone` | YES | — | — | Nullable; timestamp-order CHECK | Optional call answer timestamp. |
| `calls` | `ended_at` | `timestamp with time zone` | YES | — | — | Nullable; timestamp-order CHECK | Optional call end timestamp. |
| `calls` | `status` | `text` | NO | — | — | NOT NULL; allowed-value CHECK | Final or current call status. |
| `chat_members` | `chat_id` | `bigint` | NO | PK | chats.chat_id | Composite PRIMARY KEY; FOREIGN KEY | Chat associated with the membership. |
| `chat_members` | `user_id` | `bigint` | NO | PK | users.user_id | Composite PRIMARY KEY; FOREIGN KEY | User participating in the chat. |
| `chat_members` | `role` | `text` | NO | — | — | NOT NULL; allowed-value CHECK | Member's role in the chat. |
| `chat_members` | `joined_at` | `timestamp with time zone` | NO | — | — | NOT NULL | Timestamp when the user joined. |
| `chat_members` | `left_at` | `timestamp with time zone` | YES | — | — | Nullable; timestamp-order CHECK | Optional timestamp when the user left. |
| `chat_members` | `is_muted` | `boolean` | NO | — | — | NOT NULL | Indicates whether the chat is muted for the user. |
| `chats` | `chat_id` | `bigint` | NO | PK | — | PRIMARY KEY; positive-value CHECK | Unique identifier for a chat. |
| `chats` | `chat_type` | `text` | NO | — | — | NOT NULL; allowed-value CHECK | Identifies a direct or group chat. |
| `chats` | `group_name` | `text` | YES | — | — | Conditional CHECK based on chat_type | Name of a group chat; NULL for direct chats. |
| `chats` | `created_by` | `bigint` | NO | — | users.user_id | NOT NULL; FOREIGN KEY | User who created the chat. |
| `chats` | `created_at` | `timestamp with time zone` | NO | — | — | NOT NULL | Chat creation timestamp. |
| `devices` | `device_id` | `bigint` | NO | PK | — | PRIMARY KEY; positive-value CHECK | Unique identifier for a registered device. |
| `devices` | `user_id` | `bigint` | NO | — | users.user_id | NOT NULL; FOREIGN KEY | User who owns the device. |
| `devices` | `device_type` | `text` | NO | — | — | NOT NULL; allowed-value CHECK | Platform or device category. |
| `devices` | `app_version` | `text` | NO | — | — | NOT NULL; version-format CHECK | Installed application version. |
| `devices` | `registered_at` | `timestamp with time zone` | NO | — | — | NOT NULL | Device registration timestamp. |
| `devices` | `last_active_at` | `timestamp with time zone` | NO | — | — | NOT NULL; timestamp-order CHECK | Most recent device activity timestamp. |
| `media` | `media_id` | `bigint` | NO | PK | — | PRIMARY KEY; positive-value CHECK | Unique identifier for a media file. |
| `media` | `uploader_id` | `bigint` | NO | — | users.user_id | NOT NULL; FOREIGN KEY | User who uploaded the media. |
| `media` | `media_type` | `text` | NO | — | — | NOT NULL; allowed-value CHECK | Category of the media file. |
| `media` | `mime_type` | `text` | NO | — | — | NOT NULL | MIME format of the uploaded file. |
| `media` | `size_bytes` | `bigint` | NO | — | — | NOT NULL; positive-value CHECK | File size in bytes. |
| `media` | `sha256` | `character` | NO | — | — | NOT NULL; 64-character hexadecimal CHECK | SHA-256 file hash for integrity identification. |
| `media` | `uploaded_at` | `timestamp with time zone` | NO | — | — | NOT NULL | Media upload timestamp. |
| `message_receipts` | `message_id` | `bigint` | NO | PK | messages.message_id | Composite PRIMARY KEY; FOREIGN KEY | Message whose delivery/read status is recorded. |
| `message_receipts` | `user_id` | `bigint` | NO | PK | users.user_id | Composite PRIMARY KEY; FOREIGN KEY | Recipient whose receipt status is recorded. |
| `message_receipts` | `delivered_at` | `timestamp with time zone` | YES | — | — | Nullable; no additional column-level CHECK | Optional delivery timestamp. |
| `message_receipts` | `read_at` | `timestamp with time zone` | YES | — | — | Nullable; delivery/read timestamp CHECK | Optional read timestamp. |
| `messages` | `message_id` | `bigint` | NO | PK | — | PRIMARY KEY; positive-value CHECK | Unique identifier for a message. |
| `messages` | `chat_id` | `bigint` | NO | — | chats.chat_id | NOT NULL; FOREIGN KEY | Chat in which the message was sent. |
| `messages` | `sender_id` | `bigint` | NO | — | users.user_id | NOT NULL; FOREIGN KEY | User who sent the message. |
| `messages` | `sent_at` | `timestamp with time zone` | NO | — | — | NOT NULL | Message sending timestamp. |
| `messages` | `message_type` | `text` | NO | — | — | NOT NULL; allowed-value CHECK | Category of the message. |
| `messages` | `body` | `text` | YES | — | — | Nullable; no additional column-level CHECK | Optional textual content of the message. |
| `messages` | `media_id` | `bigint` | YES | — | media.media_id | Nullable; FOREIGN KEY | Optional linked media file. |
| `messages` | `reply_to_message_id` | `bigint` | YES | — | messages.message_id | Nullable; self-referencing FOREIGN KEY; cannot reference itself | Optional message being replied to. |
| `messages` | `is_forwarded` | `boolean` | NO | — | — | NOT NULL | Indicates whether the message was forwarded. |
| `messages` | `is_deleted` | `boolean` | NO | — | — | NOT NULL; deleted-body CHECK | Indicates whether the message is deleted. |
| `messages` | `edited_at` | `timestamp with time zone` | YES | — | — | Nullable; timestamp-order CHECK | Optional timestamp of the last edit. |
| `users` | `user_id` | `bigint` | NO | PK | — | PRIMARY KEY; CHECK user_id > 0 | Unique identifier for each user. |
| `users` | `phone_e164` | `character varying` | NO | UNIQUE | — | NOT NULL; UNIQUE; E.164 format CHECK | User's unique phone number in international format. |
| `users` | `display_name` | `text` | NO | — | — | NOT NULL; non-empty CHECK | Name displayed to other users. |
| `users` | `about` | `text` | YES | — | — | Nullable; no additional column-level CHECK | Optional user profile description. |
| `users` | `is_business` | `boolean` | NO | — | — | NOT NULL | Indicates whether the account is a business account. |
| `users` | `joined_on` | `date` | NO | — | — | NOT NULL | Date the user joined the platform. |
| `users` | `last_seen_at` | `timestamp with time zone` | YES | — | — | Nullable; no additional column-level CHECK | Most recent recorded user activity. |
| `users` | `status` | `text` | NO | — | — | NOT NULL; allowed-value CHECK | Current account status. |

## 4. Functional Dependencies

The functional dependencies are based on the declared primary keys, the unique phone number constraint and the stated business rules.

1. users:
   - user_id → phone_e164, display_name, about, is_business, joined_on, last_seen_at, status
   - phone_e164 → user_id, display_name, about, is_business, joined_on, last_seen_at, status

2. devices:
   - device_id → user_id, device_type, app_version, registered_at, last_active_at

3. chats:
   - chat_id → chat_type, group_name, created_by, created_at

4. chat_members:
   - (chat_id, user_id) → role, joined_at, left_at, is_muted

5. media:
   - media_id → uploader_id, media_type, mime_type, size_bytes, sha256, uploaded_at

6. messages:
   - message_id → chat_id, sender_id, sent_at, message_type, body, media_id, reply_to_message_id, is_forwarded, is_deleted, edited_at

7. message_receipts:
   - (message_id, user_id) → delivered_at, read_at

8. calls:
   - call_id → chat_id, caller_id, call_type, started_at, answered_at, ended_at, status

9. blocked_users:
   - (blocker_id, blocked_id) → blocked_at

Foreign keys represent relationships between relations; they do not independently establish additional functional dependencies unless a corresponding uniqueness rule exists.

The media table does not enforce media_type → mime_type. A media category may support multiple MIME formats. The supplied dataset currently contains one MIME format per category, but this observed sample pattern is not treated as a general business-rule dependency.

## 5. First Normal Form (1NF)

All nine relations satisfy 1NF based on the supplied CSV structure and schema design.

- Each column stores a single value per row.
- There are no repeating groups or arrays of values.
- Each relation has a primary key.
- Multi-valued relationships such as chat membership and message receipts are represented as separate relations.

## 6. Second Normal Form (2NF)

All nine relations satisfy 2NF under the identified functional dependencies.

- Relations with single-column primary keys cannot have partial dependencies on a proper subset of the primary key.
- In chat_members, all non-key attributes depend on the complete composite key (chat_id, user_id).
- In message_receipts, delivered_at and read_at depend on the complete composite key (message_id, user_id).
- In blocked_users, blocked_at depends on the complete composite key (blocker_id, blocked_id).

No partial functional dependencies have been identified.

## 7. Third Normal Form (3NF)

All nine relations satisfy 3NF under the functional dependencies and business rules documented above.

- Every non-key attribute depends on a candidate key.
- User details are stored in users rather than repeated in devices, messages, chats or calls.
- Chat membership details are stored separately in chat_members.
- Media metadata is stored separately in media and referenced by messages.
- Delivery and read timestamps are stored in message_receipts rather than duplicated in messages.
- No transitive functional dependencies have been identified in the declared relation design.

The media_type and mime_type columns are not treated as a separate determinant-dependent pair. The schema permits multiple MIME formats for a media category.

## 8. Boyce-Codd Normal Form (BCNF)

All nine relations satisfy BCNF under the identified functional dependencies and stated business rules.

For every documented non-trivial functional dependency, the determinant is a candidate key or a superkey.

- users: user_id and phone_e164 are candidate keys.
- Single-ID relations: their primary keys determine all other attributes.
- Composite-key relations: the complete composite key determines all non-key attributes.
- media: media_id is the determinant of the remaining attributes. media_type does not determine mime_type under the updated business rules.

This conclusion depends on the documented business rules. Additional business dependencies not represented in the requirements may require reassessment.

## 9. Redundancy and Design Decisions

- User information is stored once in users and referenced through user_id.
- Device records are separated because one user can own multiple devices.
- Chat participants are stored in chat_members because chats and users have a many-to-many relationship.
- Media metadata is stored separately to avoid repeating file details in messages.
- Receipts are stored separately because a message can have multiple recipients.
- Blocking relationships are stored in blocked_users using a composite key.
- Nullable fields such as last_seen_at, left_at, delivered_at, read_at, media_id and edited_at represent optional information in the supplied dataset.
- Message media references are optional. The supplied data contains some AUDIO, DOCUMENT, IMAGE and VIDEO messages without a media_id, so the schema does not enforce a mandatory media reference for these message types.

### 9.1 Derived and Potentially Redundant Attributes

The following values can be calculated from existing records and are not stored as separate columns:

| Derived Value | How It Can Be Calculated | Design Decision |
|---|---|---|
| Number of chat members | COUNT(*) from chat_members grouped by chat_id | Not stored separately because membership changes could make a stored count inconsistent. |
| Unread message count | Count messages for a user that do not have a corresponding read receipt | Not stored separately because read status changes frequently and can be derived from messages and message_receipts. |
| Call duration | ended_at - started_at for completed calls | Not stored separately because it can be calculated from the call timestamps. |

**Media type and message type:**

The media.media_type column describes the category of the uploaded file, whereas messages.message_type describes the category of the message sent in a chat. These attributes have related meanings for media messages, but they belong to different entities.

Both columns are retained because media metadata and message classification serve different purposes. The schema does not enforce a direct equality between them. This avoids assuming that every message must have a media record, especially because 557 non-text messages in the supplied dataset have a NULL media_id.

## 10. Integrity and Referential Design

- Primary keys uniquely identify records.
- Foreign keys maintain relationships between parent and child tables.
- Composite primary keys prevent duplicate membership, receipt and blocking pairs.
- CHECK constraints validate enumerated values, positive identifiers, timestamp ordering, phone number format, media metadata and other business rules.
- ON DELETE RESTRICT is used for foreign-key relationships to prevent accidental deletion of referenced records.

## 11. Normalization Conclusion

The nine-table design satisfies 1NF, 2NF, 3NF and BCNF under the functional dependencies and business rules identified for this project. Primary keys, candidate keys and foreign keys define the relational structure. Composite keys prevent duplicate relationship records, while the separation of independent entities reduces avoidable duplication.

The media schema permits multiple MIME formats within a media category, avoiding an unsupported media_type → mime_type dependency.



## 12. Integrity Check Results and Data Observations

The following checks were executed on the loaded PostgreSQL database. All checks returned zero violations except the documented media observation below.

| Check | Violations |
|---|---:|
| Invalid phone format | 0 |
| Duplicate phone numbers | 0 |
| Orphan messages | 0 |
| Orphan receipts | 0 |
| Orphan devices | 0 |
| Invalid group names | 0 |
| Deleted messages with non-NULL body | 0 |
| Edited timestamp before sent timestamp | 0 |
| Invalid receipt timestamp order | 0 |
| Invalid membership timestamp order | 0 |
| Invalid device timestamp order | 0 |
| Self-blocking relationships | 0 |
| Call answered before start | 0 |
| Call ended before start | 0 |
| Call ended before answer | 0 |
| TEXT messages with media reference | 0 |

All 15 foreign-key relationships were also checked for orphan references; zero orphan rows were found.

**Dataset observations:**

- 557 AUDIO, DOCUMENT, IMAGE and VIDEO messages have a NULL media_id and NULL body. The current schema permits an optional media reference, so these records are documented as a dataset observation rather than treated as a schema violation. No mandatory-media constraint has been added.
- 2,391 LOCATION messages have a NULL media_id. Of these, 2,355 contain location-sharing text in the body, while 36 have a NULL body and are marked as deleted.
- The 36 deleted LOCATION messages have a NULL body, consistent with the deleted-message integrity rule.


## 13. Constraint Catalogue

The live PostgreSQL database contains 30 CHECK constraints, 15 foreign keys, 9 primary keys, 1 UNIQUE constraint and 46 NOT NULL constraints.

### CHECK constraints and their purpose

| Table | Rule enforced | Purpose |
|---|---|---|
| users | user_id > 0 | Prevents non-positive user IDs |
| users | Valid E.164 phone format | Ensures valid international phone format |
| users | Non-empty display_name | Prevents blank names |
| users | status in ACTIVE, BANNED, DELETED | Restricts user status values |
| devices | device_id > 0 | Prevents non-positive device IDs |
| devices | Allowed device_type values | Restricts device categories |
| devices | Semantic version format for app_version | Validates app version structure |
| devices | last_active_at >= registered_at | Maintains timestamp order |
| chats | chat_id > 0 | Prevents non-positive chat IDs |
| chats | chat_type is DIRECT or GROUP | Restricts chat categories |
| chats | GROUP requires a non-empty group_name; DIRECT requires NULL | Maintains chat-type consistency |
| chat_members | role is ADMIN or MEMBER | Restricts membership roles |
| chat_members | left_at is NULL or >= joined_at | Maintains membership timestamp order |
| media | media_id > 0 | Prevents non-positive media IDs |
| media | Allowed media_type values | Restricts media categories |
| media | size_bytes > 0 | Prevents empty or negative file sizes |
| media | sha256 contains 64 hexadecimal characters | Validates file hash format |
| messages | message_id > 0 | Prevents non-positive message IDs |
| messages | Allowed message_type values | Restricts message categories |
| messages | Deleted messages must have NULL body | Prevents retaining body text on deleted messages |
| messages | edited_at is NULL or >= sent_at | Maintains edit timestamp order |
| messages | A message cannot reply to itself | Prevents self-referencing replies |
| message_receipts | read_at requires delivered_at and cannot precede it | Maintains receipt timestamp order |
| calls | call_id > 0 | Prevents non-positive call IDs |
| calls | call_type is VOICE or VIDEO | Restricts call categories |
| calls | Allowed call status values | Restricts call status |
| calls | answered_at is NULL or >= started_at | Validates answer timestamp |
| calls | ended_at is NULL or >= started_at | Validates end timestamp |
| calls | ended_at is NULL or >= answered_at when both exist | Maintains call event order |
| blocked_users | blocker_id <> blocked_id | Prevents users from blocking themselves |

### Foreign-key relationships

All foreign keys use ON DELETE RESTRICT to prevent deletion of referenced parent records.

| Child table | Column | Referenced table |
|---|---|---|
| devices | user_id | users(user_id) |
| chats | created_by | users(user_id) |
| chat_members | chat_id | chats(chat_id) |
| chat_members | user_id | users(user_id) |
| media | uploader_id | users(user_id) |
| messages | chat_id | chats(chat_id) |
| messages | sender_id | users(user_id) |
| messages | media_id | media(media_id) |
| messages | reply_to_message_id | messages(message_id) |
| message_receipts | message_id | messages(message_id) |
| message_receipts | user_id | users(user_id) |
| calls | chat_id | chats(chat_id) |
| calls | caller_id | users(user_id) |
| blocked_users | blocker_id | users(user_id) |
| blocked_users | blocked_id | users(user_id) |

### Primary, unique and NOT NULL constraints

Each table has a primary key. The chat_members, message_receipts and blocked_users tables use composite primary keys to prevent duplicate relationship pairs. The users table additionally enforces UNIQUE(phone_e164).

NOT NULL constraints ensure that required identifiers, relationship columns, timestamps and other mandatory attributes cannot be omitted. Nullable attributes represent optional information, as described in the data dictionary.
