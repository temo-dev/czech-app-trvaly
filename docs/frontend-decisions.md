# Frontend Decisions

## State management
- Riverpod

## Routing
- go_router

## API / networking
- Dio

## Model generation
- freezed + json_serializable

## Local caching
- shared_preferences for lightweight flags
- local db later if needed for offline-lite

## Design tokens source
- derived from Stitch-approved UI

## Backend integration
- Supabase for auth/data
- AWS S3 for media
- separate AI service for speaking/writing

## Form strategy
- simple controlled forms for MVP

## Responsive rule
- mobile-first
- web gets wider containers and richer layout, not different flows