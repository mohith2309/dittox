## 2024-06-25 - Flutter nested `shrinkWrap: true` `ListView` inside `ListView`
**Learning:** Using a nested `ListView.builder` with `shrinkWrap: true` inside another `ListView` is a major performance anti-pattern. This forces the framework to synchronously calculate sizes and render the entire list instead of utilizing the lazy-loading capabilities of `ListView.builder`.
**Action:** Replace `ListView` wrapping a static header and a `shrinkWrap: true` `ListView.builder` with a single, un-nested `ListView.builder` and adjust `itemCount` + array indices appropriately.
