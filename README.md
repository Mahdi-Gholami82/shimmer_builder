# shimmer_builder

provides widgets for showing skeleton placeholders using a shimmer effect

## Basic Usage
```dart
Shimmer(
    enable: true,
    child: ListView.builder(
        itemCount: 6,
        itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ListTile(
            leading: ShimmerPaintOver(
            child: Icon(Icons.account_circle_outlined, size: 40),
            ),
            title: ShimmerBuilder(
            childBuilder: (context) => Text("child number $index"),
            sampleBuilder: (context) => Text("child sample 1"),
            ),
            subtitle: ShimmerPaintOver(child: Text("subtitle")),
        ),
        ),
    ),
),
```


