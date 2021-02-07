<script lang="ts">
  export let creator: {
    user: string;
    title: string;
    creatorContract: string;
    subscriptionPrice: number;
    metadataURL: string;
  };

  var metadata;
  var creatorInfo = {
    name: {description: ''},
    image: {description: ''},
  };

  onMount(async () => {
    const response = await fetch(creator.metadataURL);
    metadata = await response.json();
    creatorInfo = metadata.properties;
    console.log(creatorInfo);
  });

  import Link from '../_routing/curi/Link.svelte';
  import {onMount} from 'svelte';
</script>

<Link
  id={creator.creatorContract}
  params={{id: creator.creatorContract}}
  name="Creator"
  class="block px-4 py-8 border rounded overflow-hidden">
  <h3 class="text-4xl leading-normal font-medium text-gray-900 truncate">{creatorInfo.name.description}</h3>
  <img class="object-contain h-80 w-full" src={creatorInfo.image.description} alt={creatorInfo.name.description} />
  <h3 class="text-1xl mt-3 leading-normal font-medium text-gray-900 truncate">
    Monthly fee: ${creator.subscriptionPrice}
  </h3>
  <p class="mt-2 text-base leading-6 text-gray-500 truncate mx-10">
    <slot />
  </p>
</Link>
