<script lang="ts">
  import { useNuiEvent } from "../utils/useNuiEvent";
  import { fetchNui } from "../utils/fetchNui";
  import { onMount } from "svelte";
  import { visibility } from "../store/stores";
  import ATM from "../components/ATM.svelte";
  import {
    showATM,
    atmCurrency,
    showOverview,
    showHistory,
    showWithdraw,
    showDeposit,
    showStats,
    showCreditCard,
    showCompanies,
  } from "../store/data";

  let isVisible: boolean;

  useNuiEvent<string>("openATM", (data) => {
    showATM.set(true);
    atmCurrency.set(data);
  });

  visibility.subscribe((visible) => {
    isVisible = visible;
  });

  useNuiEvent<boolean>("openBank", () => {
    visibility.set(true);
    showOverview.set(true);
    showHistory.set(false);
    showWithdraw.set(false);
    showDeposit.set(false);
    showStats.set(false);
    showCreditCard.set(false);
    showCompanies.set(false);
  });
  useNuiEvent<boolean>("hideGarageMenu", () => {
    visibility.set(false);
  });
  onMount(() => {
    const keyHandler = (e: KeyboardEvent) => {
      if (isVisible && ["Escape"].includes(e.code)) {
        fetchNui("fd_banking:client:hideUI");
        visibility.set(false);
      }
    };

    window.addEventListener("keydown", keyHandler);

    return () => window.removeEventListener("keydown", keyHandler);
  });
</script>

<main>
  {#if isVisible}
    <slot />
  {/if}
  {#if $showATM}
    <ATM />
  {/if}
</main>
