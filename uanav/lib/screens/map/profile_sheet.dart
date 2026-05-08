import 'package:flutter/material.dart';
import '../../models/campus_graph.dart';
import '../../services/auth_service.dart';

enum ProfileSheetAction { saved, signOut }

class ProfileSheetResult {
  const ProfileSheetResult.saved(this.profileName)
    : action = ProfileSheetAction.saved;

  const ProfileSheetResult.signOut()
    : action = ProfileSheetAction.signOut,
      profileName = null;

  final ProfileSheetAction action;
  final String? profileName;
}

// Displays a bottom sheet allowing the user to view and edit their profile information,
// sign in/out, and access their favorite places.
Future<ProfileSheetResult?> showMapProfileSheet({
  required BuildContext context,
  required bool signedIn,
  required String profileName,
  required String? accountEmail,
  required bool signingOut,
  required bool canSignOut,
  required List<CampusPlace> favoritePlaces,
  required Future<void> Function(String profileName) onSaveProfile,
}) {
  return showModalBottomSheet<ProfileSheetResult>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      var draftName = profileName;
      var savingProfile = false;
      String? sheetError;

      return SafeArea(
        child: StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'UANav Account',
                    style: TextStyle(
                      color: Color(ualbanyPurple),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _AccountStatus(signedIn: signedIn, email: accountEmail),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: profileName,
                    onChanged: (value) => draftName = value,
                    decoration: InputDecoration(
                      labelText: signedIn ? 'Display name' : 'Profile name',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  // Show error message if profile saving fails
                  if (sheetError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      sheetError!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  // Save profile button
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(ualbanyPurple),
                    ),
                    icon: savingProfile
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(signedIn ? 'Save Changes' : 'Save profile'),
                    onPressed: savingProfile
                        ? null
                        : () async {
                            final trimmedName = draftName.trim();
                            final finalName = trimmedName.isEmpty
                                ? AuthService.defaultDisplayName
                                : trimmedName;

                            setSheetState(() {
                              savingProfile = true;
                              sheetError = null;
                            });

                            try {
                              await onSaveProfile(finalName);
                              if (!sheetContext.mounted) {
                                return;
                              }
                              Navigator.of(
                                sheetContext,
                              ).pop(ProfileSheetResult.saved(finalName));
                            } catch (_) {
                              if (!sheetContext.mounted) {
                                return;
                              }
                              setSheetState(() {
                                savingProfile = false;
                                sheetError =
                                    'Profile could not be saved. Try again.';
                              });
                            }
                          },
                  ),
                  // Sign out button (only if user is signed in and sign out is allowed)
                  if (canSignOut) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(ualbanyPurple),
                      ),
                      icon: Icon(signedIn ? Icons.logout : Icons.login),
                      label: Text(
                        signedIn ? 'Sign out' : 'Sign in or create account',
                      ),
                      onPressed: signingOut
                          ? null
                          : () => Navigator.of(
                              sheetContext,
                            ).pop(const ProfileSheetResult.signOut()),
                    ),
                  ],
                  // Favorite places list
                  const SizedBox(height: 16),
                  Text(
                    'Favorites (${favoritePlaces.length})',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  if (favoritePlaces.isEmpty)
                    Text(
                      'No favorites yet',
                      style: TextStyle(color: Colors.grey[700]),
                    )
                  else
                    ...favoritePlaces
                        .take(4)
                        .map(
                          (place) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.star,
                              color: Color(ualbanyGold),
                            ),
                            title: Text(place.name),
                          ),
                        ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

// Displays the user's account status (signed in or guest) along with their email if available.
class _AccountStatus extends StatelessWidget {
  const _AccountStatus({required this.signedIn, required this.email});

  final bool signedIn;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          signedIn ? Icons.verified_user_outlined : Icons.person_outline,
          color: const Color(ualbanyPurple),
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            signedIn
                ? 'Signed in${email == null ? '' : ' as $email'}'
                : 'Guest account',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
