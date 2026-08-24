import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'greek_painters.dart';
import 'greek_tokens.dart';

class GreekPageShell extends StatelessWidget {
  const GreekPageShell({
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
    backgroundColor: Colors.transparent,
    resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    appBar: topBar,
    bottomNavigationBar: bottomBar,
    body: Stack(children: [const GreekMarbleBackground(), body]),
  );
}

class GreekTopBar extends StatelessWidget implements PreferredSizeWidget {
  const GreekTopBar({
    this.title,
    this.subtitle,
    this.brand = false,
    this.showBack = false,
    this.actions = const [],
    this.onBack,
    this.compact = false,
    super.key,
  });

  final String? title;
  final String? subtitle;
  final bool brand;
  final bool showBack;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final bool compact;

  @override
  Size get preferredSize => Size.fromHeight(compact ? 62 : 76);

  @override
  Widget build(BuildContext context) => Material(
    color: GreekColors.marbleLight,
    child: Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 10, 3),
            child: Row(
              children: [
                if (showBack)
                  GreekIconButton(
                    icon: Icons.arrow_back,
                    semanticLabel: 'Kembali',
                    onPressed: onBack ?? () => Navigator.maybePop(context),
                  ),
                if (showBack) const SizedBox(width: 4),
                Expanded(
                  child: brand
                      ? const GreekBrandMark()
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(color: GreekColors.aegeanDeep),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: GreekColors.terracotta,
                                      fontFeatures: tabularFigures,
                                    ),
                              ),
                          ],
                        ),
                ),
                ...actions,
              ],
            ),
          ),
        ),
        const GreekKeyBorder(height: 9),
      ],
    ),
  );
}

class GreekBrandMark extends StatelessWidget {
  const GreekBrandMark({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Repr. ΑΡΕΤΗ. Track every rep.',
    child: ExcludeSemantics(
      child: Row(
        children: [
          const GreekTempleMark(size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: MediaQuery.withNoTextScaling(
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REPR',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: GreekColors.aegeanDeep,
                      fontFamily: 'NotoSerif',
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'ΑΡΕΤΗ  •  TRACK EVERY REP',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: GreekColors.terracotta,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .65,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class GreekBottomDestination {
  const GreekBottomDestination({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class GreekBottomNav extends StatelessWidget {
  const GreekBottomNav({
    required this.currentIndex,
    required this.destinations,
    required this.onSelected,
    super.key,
  });

  final int currentIndex;
  final List<GreekBottomDestination> destinations;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Material(
    color: GreekColors.marbleLight,
    elevation: 8,
    shadowColor: GreekColors.ink.withValues(alpha: .25),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GreekKeyBorder(height: 9),
          SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < destinations.length; i++)
                  Expanded(
                    child: _GreekNavItem(
                      destination: destinations[i],
                      selected: currentIndex == i,
                      onTap: () => onSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _GreekNavItem extends StatelessWidget {
  const _GreekNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });
  final GreekBottomDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    label: destination.label,
    child: InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: GreekMotion.resolve(context, GreekMotion.quick),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: selected ? GreekColors.bronze : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              destination.icon,
              size: 22,
              color: selected ? GreekColors.aegeanDeep : GreekColors.inkMuted,
            ),
            const SizedBox(height: 3),
            Text(
              destination.label.toUpperCase(),
              style: TextStyle(
                color: selected ? GreekColors.aegeanDeep : GreekColors.inkMuted,
                fontSize: 9,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: .65,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class GreekPanel extends StatelessWidget {
  const GreekPanel({
    required this.child,
    this.variant = GreekPanelVariant.stone,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final GreekPanelVariant variant;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  Color get _background => switch (variant) {
    GreekPanelVariant.active => GreekColors.terracottaPale,
    GreekPanelVariant.success => GreekColors.olivePale,
    GreekPanelVariant.warning => const Color(0xFFF2E5C1),
    GreekPanelVariant.stone => GreekColors.marbleLight,
  };

  Color get _border => switch (variant) {
    GreekPanelVariant.active => GreekColors.terracotta,
    GreekPanelVariant.success => GreekColors.olive,
    GreekPanelVariant.warning => GreekColors.bronze,
    GreekPanelVariant.stone => GreekColors.limestoneDark,
  };

  @override
  Widget build(BuildContext context) {
    final content = ClipPath(
      clipper: const GreekCutCornerClipper(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _border,
          boxShadow: [
            BoxShadow(
              color: GreekColors.ink.withValues(alpha: .08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: ClipPath(
            clipper: const GreekCutCornerClipper(cut: 6),
            child: ColoredBox(
              color: _background,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

class GreekButton extends StatelessWidget {
  const GreekButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = GreekActionVariant.primary,
    this.expand = true,
    this.compact = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final GreekActionVariant variant;
  final bool expand;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final background = switch (variant) {
      GreekActionVariant.primary => GreekColors.aegean,
      GreekActionVariant.secondary => GreekColors.marbleLight,
      GreekActionVariant.destructive => GreekColors.danger,
      GreekActionVariant.quiet => Colors.transparent,
    };
    final foreground = switch (variant) {
      GreekActionVariant.primary ||
      GreekActionVariant.destructive => GreekColors.marbleLight,
      GreekActionVariant.secondary ||
      GreekActionVariant.quiet => GreekColors.aegeanDeep,
    };
    final border = variant == GreekActionVariant.quiet
        ? Colors.transparent
        : variant == GreekActionVariant.destructive
        ? GreekColors.danger
        : GreekColors.bronze;
    final child = Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Opacity(
        opacity: enabled ? 1 : .45,
        child: ClipPath(
          clipper: const GreekCutCornerClipper(cut: 6),
          child: Material(
            color: background,
            child: InkWell(
              onTap: onPressed,
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                decoration: BoxDecoration(border: Border.all(color: border)),
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 18,
                  vertical: compact ? 8 : 12,
                ),
                child: Row(
                  mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) Icon(icon, color: foreground, size: 19),
                    if (icon != null) const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground,
                          fontSize: compact ? 11 : 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: child) : child;
  }
}

class GreekIconButton extends StatelessWidget {
  const GreekIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.danger = false,
    super.key,
  });
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticLabel,
    enabled: onPressed != null,
    child: SizedBox.square(
      dimension: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Icon(
            icon,
            color: danger ? GreekColors.danger : GreekColors.aegeanDeep,
            size: 21,
          ),
        ),
      ),
    ),
  );
}

class GreekTextField extends StatelessWidget {
  const GreekTextField({
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
  Widget build(BuildContext context) => Opacity(
    opacity: enabled ? 1 : .58,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!.toUpperCase(),
            style: const TextStyle(
              color: GreekColors.bronzeDeep,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 5),
        ],
        ClipPath(
          clipper: const GreekCutCornerClipper(cut: 5),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(
              color: GreekColors.marbleLight,
              border: Border.all(
                color: errorText == null
                    ? GreekColors.limestoneDark
                    : GreekColors.danger,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  Icon(leading, size: 19, color: GreekColors.aegean),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    initialValue: controller == null ? initialValue : null,
                    enabled: enabled,
                    keyboardType: keyboardType,
                    inputFormatters: inputFormatters,
                    maxLines: maxLines,
                    onChanged: onChanged,
                    decoration: InputDecoration.collapsed(hintText: hint),
                    style: TextStyle(
                      color: GreekColors.ink,
                      fontSize: 15,
                      fontFeatures: numeric ? tabularFigures : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: const TextStyle(color: GreekColors.danger, fontSize: 11),
          ),
        ],
      ],
    ),
  );
}

class GreekSegment<T> {
  const GreekSegment({required this.value, required this.label});
  final T value;
  final String label;
}

class GreekSegmentedControl<T> extends StatelessWidget {
  const GreekSegmentedControl({
    required this.segments,
    required this.value,
    required this.onChanged,
    super.key,
  });
  final List<GreekSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => ClipPath(
    clipper: const GreekCutCornerClipper(cut: 5),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: GreekColors.marbleLight,
        border: Border.all(color: GreekColors.limestoneDark),
      ),
      child: Row(
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0) const SizedBox(height: 48, child: VerticalDivider()),
            Expanded(
              child: Semantics(
                selected: segments[i].value == value,
                button: true,
                child: InkWell(
                  onTap: () => onChanged(segments[i].value),
                  child: AnimatedContainer(
                    duration: GreekMotion.resolve(context, GreekMotion.quick),
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 11,
                    ),
                    color: segments[i].value == value
                        ? GreekColors.aegean
                        : Colors.transparent,
                    child: Text(
                      segments[i].label.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                        color: segments[i].value == value
                            ? GreekColors.marbleLight
                            : GreekColors.aegeanDeep,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class GreekToggle extends StatelessWidget {
  const GreekToggle({required this.value, required this.onChanged, super.key});
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    button: true,
    child: SizedBox(
      width: 56,
      height: 48,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: Center(
          child: AnimatedContainer(
            duration: GreekMotion.resolve(context, GreekMotion.quick),
            width: 52,
            height: 30,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: value ? GreekColors.olive : GreekColors.limestone,
              border: Border.all(
                color: value ? GreekColors.olive : GreekColors.limestoneDark,
              ),
            ),
            child: AnimatedAlign(
              duration: GreekMotion.resolve(context, GreekMotion.quick),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                color: GreekColors.marbleLight,
                child: value
                    ? const Icon(
                        Icons.check,
                        size: 15,
                        color: GreekColors.olive,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class GreekCheckTile extends StatelessWidget {
  const GreekCheckTile({
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
  Widget build(BuildContext context) => Semantics(
    checked: value,
    button: true,
    child: InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: GreekColors.inkMuted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: value ? GreekColors.olive : Colors.transparent,
                  border: Border.all(
                    color: value ? GreekColors.olive : GreekColors.bronze,
                    width: 1.5,
                  ),
                ),
                child: value
                    ? const Icon(
                        Icons.check,
                        color: GreekColors.white,
                        size: 18,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class GreekListRow extends StatelessWidget {
  const GreekListRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.minHeight = 64,
    super.key,
  });
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final double minHeight;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    child: InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: GreekColors.inkMuted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    ),
  );
}

class GreekMedallion extends StatelessWidget {
  const GreekMedallion({required this.child, this.active = false, super.key});
  final Widget child;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: active ? GreekColors.aegean : GreekColors.marble,
      border: Border.all(color: GreekColors.bronze, width: 1.5),
    ),
    child: DefaultTextStyle(
      style: TextStyle(
        color: active ? GreekColors.marbleLight : GreekColors.aegeanDeep,
        fontFamily: 'NotoSerif',
        fontWeight: FontWeight.w700,
      ),
      child: child,
    ),
  );
}

class GreekStatPlaque extends StatelessWidget {
  const GreekStatPlaque({required this.label, required this.value, super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => GreekPanel(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    child: Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: GreekColors.aegeanDeep,
              fontFeatures: tabularFigures,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: GreekColors.terracotta,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: .6,
          ),
        ),
      ],
    ),
  );
}

class GreekEmptyState extends StatelessWidget {
  const GreekEmptyState({
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
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GreekMedallion(
            child: Icon(icon, color: GreekColors.aegeanDeep, size: 22),
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 7),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: GreekColors.inkMuted),
          ),
        ],
      ),
    ),
  );
}

class GreekMottoBanner extends StatelessWidget {
  const GreekMottoBanner({super.key});

  @override
  Widget build(BuildContext context) => GreekPanel(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
    child: Row(
      children: [
        const Text(
          'ΑΡΕΤΗ',
          style: TextStyle(
            color: GreekColors.aegeanDeep,
            fontFamily: 'NotoSerif',
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 13),
        Container(width: 1, height: 30, color: GreekColors.bronze),
        const SizedBox(width: 13),
        const Expanded(
          child: Text(
            'Keunggulan dibangun satu repetisi demi satu repetisi.',
            style: TextStyle(
              color: GreekColors.terracotta,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ],
    ),
  );
}

class GreekDialog extends StatelessWidget {
  const GreekDialog({
    required this.title,
    required this.child,
    this.actions = const [],
    super.key,
  });
  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
    child: GreekPanel(
      padding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Row(
                children: [
                  const GreekTempleMark(size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            const GreekKeyBorder(height: 8),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                child: child,
              ),
            ),
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions
                      .map(
                        (action) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: action,
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
}

Future<T?> showGreekDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: barrierDismissible,
  barrierLabel: 'Tutup dialog',
  barrierColor: GreekColors.aegeanDeep.withValues(alpha: .56),
  transitionDuration: GreekMotion.resolve(context, GreekMotion.standard),
  pageBuilder: (context, _, __) => builder(context),
  transitionBuilder: (context, animation, _, child) => FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
    child: ScaleTransition(
      scale: Tween(begin: .97, end: 1.0).animate(animation),
      child: child,
    ),
  ),
);

class GreekAction<T> {
  const GreekAction({
    required this.value,
    required this.label,
    this.danger = false,
  });
  final T value;
  final String label;
  final bool danger;
}

Future<T?> showGreekActionSheet<T>({
  required BuildContext context,
  required String title,
  required List<GreekAction<T>> actions,
}) => showModalBottomSheet<T>(
  context: context,
  backgroundColor: Colors.transparent,
  barrierColor: GreekColors.aegeanDeep.withValues(alpha: .5),
  isScrollControlled: true,
  builder: (context) => SafeArea(
    minimum: const EdgeInsets.all(12),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .82,
      ),
      child: GreekPanel(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            const GreekKeyBorder(height: 8),
            Flexible(
              fit: FlexFit.loose,
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final action in actions)
                    GreekListRow(
                      title: action.label,
                      trailing: Icon(
                        Icons.chevron_right,
                        color: action.danger
                            ? GreekColors.danger
                            : GreekColors.bronze,
                      ),
                      onTap: () => Navigator.pop(context, action.value),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);

class GreekSelect<T> extends StatelessWidget {
  const GreekSelect({
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
  Widget build(BuildContext context) => GreekPanel(
    padding: EdgeInsets.zero,
    onTap: () async {
      final selected = await showGreekActionSheet<T>(
        context: context,
        title: label,
        actions: options.entries
            .map((entry) => GreekAction(value: entry.key, label: entry.value))
            .toList(),
      );
      if (selected != null) onChanged(selected);
    },
    semanticLabel: label,
    child: GreekListRow(
      title: label,
      subtitle: value == null ? 'Pilih' : options[value],
      trailing: const Icon(Icons.expand_more, color: GreekColors.bronzeDeep),
    ),
  );
}

abstract final class GreekToast {
  static void show(
    BuildContext context,
    String message, {
    GreekNoticeKind kind = GreekNoticeKind.info,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) =>
          _GreekToastEntry(message: message, kind: kind, onDone: entry.remove),
    );
    overlay.insert(entry);
  }
}

class _GreekToastEntry extends StatefulWidget {
  const _GreekToastEntry({
    required this.message,
    required this.kind,
    required this.onDone,
  });
  final String message;
  final GreekNoticeKind kind;
  final VoidCallback onDone;

  @override
  State<_GreekToastEntry> createState() => _GreekToastEntryState();
}

class _GreekToastEntryState extends State<_GreekToastEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: GreekMotion.standard,
    );
    controller.forward();
    Future<void>.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      await controller.reverse();
      widget.onDone();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = switch (widget.kind) {
      GreekNoticeKind.success => GreekColors.olive,
      GreekNoticeKind.warning => GreekColors.bronzeDeep,
      GreekNoticeKind.error => GreekColors.danger,
      GreekNoticeKind.info => GreekColors.aegean,
    };
    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.paddingOf(context).bottom + 20,
      child: FadeTransition(
        opacity: controller,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, .2),
            end: Offset.zero,
          ).animate(controller),
          child: Material(
            color: Colors.transparent,
            child: GreekPanel(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 10, color: color),
                  const SizedBox(width: 10),
                  Expanded(child: Text(widget.message)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
