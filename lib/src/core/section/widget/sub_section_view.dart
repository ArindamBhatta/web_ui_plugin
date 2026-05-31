import 'package:flutter/material.dart';
import 'package:web_ui_plugins/web_ui_plugins.dart';

class SubSectionView extends StatelessWidget {
  final DataModel? dataModel;
  final List<Tab>? tabs;
  final List<Widget>? tabViews;
  final List<CustomButton> footerActionButtons;

  const SubSectionView({
    super.key,
    this.dataModel,
    this.tabs,
    this.tabViews,
    this.footerActionButtons = const [],
  });

  @override
  Widget build(BuildContext context) {
    final headerFooterColor = Colors.white;

    final leftButtons = footerActionButtons
        .where((b) => b.group == ButtonGroup.left)
        .toList();
    final rightButtons = footerActionButtons
        .where((b) => b.group == ButtonGroup.right)
        .toList();

    return Container(
      color: Colors.white,
      child: DefaultTabController(
        length: tabs?.length ?? 0,
        child: Column(
          children: [
            Container(
              color: headerFooterColor,
              child: SizedBox(
                height: AppTheme.formButtonHeight,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: AppTheme.sidePadding,
                    right: AppTheme.sidePadding,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (tabs != null)
                        TabBar(
                          tabs: tabs!,
                          isScrollable: true,
                          dividerColor: Colors.transparent,
                          labelColor: Theme.of(context).colorScheme.primary,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Theme.of(
                            context,
                          ).colorScheme.secondary,
                          indicatorSize: TabBarIndicatorSize.tab,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          tabAlignment: TabAlignment.start,
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text(
                            dataModel?.title?.toUpperCase() ?? '',
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Divider(
              thickness: 1,
              height: 1,
              indent: AppTheme.sidePadding + 10,
              endIndent: AppTheme.sidePadding + 10,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppTheme.sidePadding,
                  right: AppTheme.sidePadding,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: SizedBox(
                        height: constraints.maxHeight,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TabBarView(
                            children:
                                (tabViews ??
                                        [
                                          Center(
                                            child: Text(
                                              'No content available',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                            ),
                                          ),
                                        ])
                                    .map((view) {
                                      return _KeepAliveTabChild(child: view);
                                    })
                                    .toList(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            //footer
            if (footerActionButtons.isNotEmpty) ...[
              Divider(
                thickness: 1,
                height: 1,
                indent: AppTheme.sidePadding + 10,
                endIndent: AppTheme.sidePadding + 10,
              ),
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: Container(
                  color: headerFooterColor,
                  height: AppTheme.formButtonHeight,
                  padding: EdgeInsets.only(
                    left: AppTheme.sidePadding,
                    right: AppTheme.sidePadding,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: leftButtons
                                .map(
                                  (button) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: CustomButton(
                                      text: button.text,
                                      icon: button.icon,
                                      buttonType: button.buttonType,
                                      buttonState: button.buttonState,
                                      onPressed: button.onPressed,
                                      group: button.group,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: rightButtons
                                .map(
                                  (button) => Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: CustomButton(
                                      text: button.text,
                                      icon: button.icon,
                                      buttonType: button.buttonType,
                                      buttonState: button.buttonState,
                                      onPressed: button.onPressed,
                                      group: button.group,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KeepAliveTabChild extends StatefulWidget {
  final Widget child;

  const _KeepAliveTabChild({required this.child});

  @override
  State<_KeepAliveTabChild> createState() => _KeepAliveTabChildState();
}

class _KeepAliveTabChildState extends State<_KeepAliveTabChild>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
