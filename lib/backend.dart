// Central backend facade for the app.
// Export the concrete DB implementation and provide a single place
// to add API clients, auth helpers, realtime subscriptions, etc.

export 'db.dart';

// You can add additional shared helpers here in the future, for example:
// import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;
// final SupabaseClient supabaseClient = Supabase.instance.client;
