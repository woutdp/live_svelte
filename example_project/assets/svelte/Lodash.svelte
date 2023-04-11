<script lang="ts">
    import * as _ from "lodash"

    export let unordered: number[]
    let ordered = _.sortBy(unordered)
</script>

<h1>Lodash, TypeScript and Stylus Preprocessor</h1>
<p>Unordered: <code>{unordered}</code></p>
<p>Ordered: <code>{ordered}</code></p>

<style lang="stylus">
    h1
        color red
        font-weight bold
        font-size 1.5em
</style>
