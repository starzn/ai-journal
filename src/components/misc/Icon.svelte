<script lang="ts">
import { iconMap } from "./iconify-data";

interface Props {
  name?: string;
  icon?: string;
  class?: string;
}

let { name, icon, class: className }: Props = $props();
const iconName = $derived(name || icon || "");
const data = $derived(iconMap[iconName]);
</script>

{#if data}
<svg
  xmlns="http://www.w3.org/2000/svg"
  viewBox="0 0 {data.width} {data.height}"
  width="1em"
  height="1em"
  class={className}
>
  {@html data.body}
</svg>
{/if}
