/// The signed-in account. Kept minimal and provider-agnostic so the rest of
/// the app never imports Supabase types directly.
class AppUser {
  const AppUser({required this.id, required this.email});

  final String id;
  final String email;
}
