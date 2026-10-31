import 'package:alessio_test_task/auth/session.dart';
import 'package:alessio_test_task/core/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class UserBadge extends StatelessWidget {
  const UserBadge({required this.user, super.key});

  final User user;

  @override
  Widget build(BuildContext context) {
    final image = user.image;
    return Row(
      children: [
        ExcludeSemantics(
          child: CircleAvatar(
            radius: Sizes.avatar / 2,
            backgroundImage: image == null
                ? null
                : CachedNetworkImageProvider(image),
            child: image == null ? Text(_initial(user.firstName)) : null,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Flexible(
          child: Text(
            user.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

String _initial(String name) => name.isEmpty ? '' : name[0].toUpperCase();
