/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../carp_services/carp_services.dart';

/// A modal dialog shown a list of [ActiveParticipationInvitation] for the
/// user to select one from.
class ActiveParticipationInvitationDialog {
  AlertDialog build(
    BuildContext context,
    List<ActiveParticipationInvitation> invitations,
  ) => AlertDialog(
    title: const Text('Select invitation'),
    titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
    contentPadding: EdgeInsets.zero,
    content: SizedBox(
      width: double.maxFinite,
      child: ListView.builder(
        itemCount: invitations.length,
        itemBuilder: (context, index) =>
            _buildInvitationCard(context, invitations[index]),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    ],
  );

  String shortStudyDescription(String studyDescription) =>
      (studyDescription.length < 100)
      ? studyDescription
      : '${studyDescription.substring(0, 97)}...';

  Widget _buildInvitationCard(
    BuildContext context,
    ActiveParticipationInvitation invitation,
  ) => Material(
    child: InkWell(
      onTap: () {
        Navigator.pop(context, invitation);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.mail_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        invitation.invitation.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (invitation.invitation.description == null ||
                                invitation.invitation.description!.isEmpty)
                            ? 'No description provided'
                            : shortStudyDescription(
                                invitation.invitation.description!,
                              ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
