# Problem Understanding – WhatsApp Messaging Database

## 1. Project Overview

The objective of this project is to design and analyze a WhatsApp Messaging Database using PostgreSQL. The database manages users, devices, chats, group memberships, messages, media files, message receipts, calls, and blocked users.

The project focuses on identifying existing database performance problems, designing a properly structured database, and improving query performance while supporting future data growth.

## 2. Problem Statements and Stakeholders

| ID | Business Requirement | Affected Stakeholder | Classification |
|---|---|---|---|
| P1 | The chats screen takes too long to display the latest message and unread badge for each chat. | End Users / Mobile App | Customer-facing / Real-time |
| P2 | Opening a busy group and scrolling through its message history is slow. | End Users / Group Admins | Customer-facing / Real-time |
| P3 | Message search and checking who has read a particular message are slow. | End Users / Mobile App | Customer-facing / Real-time |
| P4 | Phone number lookup, last-seen information, and blocked-user checks need to respond quickly. | Identity / Privacy Team | Customer-facing / Real-time |
| P5 | Finding pending delivery receipts and updating read status are slow under heavy load. | Delivery Service | Customer-facing / Real-time |
| P6 | Group administrators need a correct report of questions that have not received replies. | Group Admins | Reporting / Analytics |
| P7 | Spam detection, forwarding analysis, and related reports need better performance. | Trust & Safety Team | Reporting / Analytics |
| P8 | The system needs to identify heavy media uploaders and detect duplicate media files. | Storage Team | Reporting / Analytics |
| P9 | Daily active users, read times, message activity, and group engagement reports are slow, especially as data grows. | Product / Growth Analytics | Reporting / Analytics |
| P10 | Finding inactive users, unused linked devices, missed calls, and group membership cleanup records is slow. | Security / Platform Team | Reporting / Analytics |

## 3. Main Stakeholders

- End Users: Need quick access to chats, messages, contacts, and read receipts.
- Group Admins: Need group information and reports about unanswered questions.
- Delivery Service: Handles message delivery and read receipts.
- Identity / Privacy Team: Handles registration, user lookup, last-seen information, and blocking checks.
- Trust & Safety Team: Monitors spam and forwarded messages.
- Storage Team: Tracks media uploads and duplicate files.
- Product / Growth Analytics: Studies user activity, message engagement, and product usage.
- Security / Platform Team: Handles inactive accounts, linked devices, missed calls, and cleanup operations.

## 4. Assumptions

1. Every WhatsApp user is identified by a unique phone number.
2. A user can register multiple devices.
3. Chats can be either direct chats or groups.
4. A user can participate in multiple chats, and a chat can contain multiple users.
5. Messages can contain text or media and may be replied to, forwarded, edited, or deleted.
6. Message delivery and read receipts are maintained separately for each recipient.
7. A user can block another user.
8. Historical message and activity data is required for reporting and analytics.
9. The database should support future data growth without changing the expected results of existing queries.

## 5. Conclusion

The project aims to rebuild a properly structured WhatsApp database, identify performance bottlenecks, and improve database operations. The database design must support both real-time application requirements and reporting requirements while remaining scalable for future growth.
