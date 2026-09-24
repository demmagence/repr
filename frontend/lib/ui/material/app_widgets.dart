import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';

class AppPageShell extends StatelessWidget {
  const AppPageShell({
    required this.body,
    this.topBar,
    this.bottomBar,
    this.resizeToAvoidBottomInset = true,
    super.key,
  });

  final Widget body;
  final PreferredSizeWidget? topBar;
  final Widget? bottomBar;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: topBar,
    body: body,
    bottomNavigationBar: bottomBar,
    resizeToAvoidBottomInset: resizeToAvoidBottomInset,
  );
}

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    this.title,
    this.subtitle,
    this.showBack = false,
    this.actions = const [],
    this.onBack,
    super.key,
  });

  final String? title;
  final String? subtitle;
  final bool showBack;
  final List<Widget> actions;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    leading: showBack
        ? IconButton(
            tooltip: 'Kembali',
            onPressed: onBack ?? () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back),
          )
        : null,
    title: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title ?? 'Repr'),
        if (subtitle != null)
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    ),
    actions: actions,
  );
}

class AppBottomDestination {
  const AppBottomDestination({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.currentIndex,
    required this.destinations,
    required this.onSelected,
    super.key,
  });

  final int currentIndex;
  final List<AppBottomDestination> destinations;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: currentIndex,
    onDestinationSelected: onSelected,
    destinations: destinations
        .map(
          (destination) => NavigationDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.icon),
            label: destination.label,
          ),
        )
        .toList(),
  );
}

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: Card(
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppActionVariant.primary,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppActionVariant variant;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = switch (variant) {
      AppActionVariant.primary =>
        icon == null
            ? FilledButton(onPressed: onPressed, child: Text(label))
            : FilledButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(label),
              ),
      AppActionVariant.secondary =>
        icon == null
            ? OutlinedButton(onPressed: onPressed, child: Text(label))
            : OutlinedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(label),
              ),
      AppActionVariant.quiet || AppActionVariant.destructive =>
        icon == null
            ? TextButton(onPressed: onPressed, child: Text(label))
            : TextButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(label),
              ),
    };
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: semanticLabel,
    onPressed: onPressed,
    icon: Icon(icon),
  );
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    this.controller,
    this.initialValue,
    this.label,
    this.hint,
    this.leading,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.enabled = true,
    this.errorText,
    this.maxLines = 1,
    this.numeric = false,
    super.key,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final String? label;
  final String? hint;
  final IconData? leading;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final String? errorText;
  final int maxLines;
  final bool numeric;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    initialValue: controller == null ? initialValue : null,
    enabled: enabled,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    maxLines: maxLines,
    onChanged: onChanged,
    style: TextStyle(fontFeatures: numeric ? tabularFigures : null),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      prefixIcon: leading == null ? null : Icon(leading),
    ),
  );
}

class AppSegment<T> {
  const AppSegment({required this.value, required this.label});
  final T value;
  final String label;
}

class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    required this.segments,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final List<AppSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SegmentedButton<T>(
      segments: segments
          .map(
            (segment) =>
                ButtonSegment(value: segment.value, label: Text(segment.label)),
          )
          .toList(),
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    ),
  );
}

class AppToggle extends StatelessWidget {
  const AppToggle({required this.value, required this.onChanged, super.key});
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) =>
      Switch(value: value, onChanged: onChanged);
}

class AppCheckTile extends StatelessWidget {
  const AppCheckTile({
    required this.value,
    required this.title,
    required this.onChanged,
    this.subtitle,
    this.leading,
    super.key,
  });

  final bool value;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
    value: value,
    onChanged: onChanged == null
        ? null
        : (next) {
            if (next != null) onChanged!(next);
          },
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    secondary: leading,
    controlAffinity: ListTileControlAffinity.trailing,
  );
}

class AppListRow extends StatelessWidget {
  const AppListRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: leading,
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    trailing: trailing,
    onTap: onTap,
  );
}

class AppAvatar extends StatelessWidget {
  const AppAvatar({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => CircleAvatar(child: child);
}

class AppStatCard extends StatelessWidget {
  const AppStatCard({required this.label, required this.value, super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(value, style: Theme.of(context).textTheme.titleLarge),
      ),
      subtitle: Text(label, textAlign: TextAlign.center),
    ),
  );
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class AppDialog extends StatelessWidget {
  const AppDialog({
    required this.title,
    required this.child,
    this.actions = const [],
    super.key,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title),
    content: child,
    actions: actions,
    scrollable: true,
  );
}

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) => showDialog<T>(
  context: context,
  barrierDismissible: barrierDismissible,
  builder: builder,
);

class AppAction<T> {
  const AppAction({required this.value, required this.label});
  final T value;
  final String label;
}

Future<T?> showAppActionSheet<T>({
  required BuildContext context,
  required String title,
  required List<AppAction<T>> actions,
}) => showModalBottomSheet<T>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: actions
                  .map(
                    (action) => ListTile(
                      title: Text(action.label),
                      onTap: () => Navigator.pop(context, action.value),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    ),
  ),
);

class AppSelect<T> extends StatelessWidget {
  const AppSelect({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
  });

  final String label;
  final T? value;
  final Map<T, String> options;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: options.entries
        .map(
          (entry) =>
              DropdownMenuItem(value: entry.key, child: Text(entry.value)),
        )
        .toList(),
    onChanged: onChanged,
  );
}

abstract final class AppToast {
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) => showDatePicker(
  context: context,
  initialDate: initialDate,
  firstDate: firstDate,
  lastDate: lastDate,
  locale: const Locale('id', 'ID'),
  helpText: 'Pilih tanggal',
  cancelText: 'Batal',
  confirmText: 'Pilih',
);
