<script lang="ts">
    import * as _ from "lodash"

    interface Props {
        unordered: number[]
    }

    let {unordered}: Props = $props()
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
