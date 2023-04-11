<script>
    import * as _ from "lodash"

    export let unordered
    let ordered = _.sortBy(unordered, i => i)
</script>

<h1>Lodash and Stylus Preprocessor</h1>
<p>Unordered: <code>{unordered}</code></p>
<p>Ordered: <code>{ordered}</code></p>

<style lang="stylus">
    h1
        color red
        font-weight bold
        font-size 1.5em
</style>
