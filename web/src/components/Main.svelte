<script lang="ts">
  import { onMount } from "svelte";
  import { writable } from "svelte/store";
  // import { useNuiEvent } from "../utils/useNuiEvent";
  import { fetchNui } from "../utils/fetchNui";
  import { visibility } from "../store/stores";
  import OverviewPage from "./Overview.svelte";
  import HistoryPage from "./History.svelte";
  import WithdrawPage from "./Withdraw.svelte";
  import DepositPage from "./Deposit.svelte";
  import CreditCardPage from "./CreditCardPage.svelte";
  import Companies from "./Companies.svelte";
  import StatsPage from "./Stats.svelte";
  import { scale } from "svelte/transition";
  import { quintOut } from "svelte/easing";
  import {
    showOverview,
    showHistory,
    showWithdraw,
    showDeposit,
    showStats,
    showCreditCard,
    showCompanies,
    Locales,
  } from "../store/data";
  import { updateBalances, getLocales } from "../store/methods";

  let canShowCompanies = writable(false);
  async function canAccessCompanies() {
    fetchNui("fd_banking:client:canAccessCompanies", {})
      .then((response) => {
        if (response.success) {
          canShowCompanies.set(response);
        }
      })
      .catch((error) => {
        console.error(error);
      });
  }

  onMount(async () => {
    updateBalances();
    getLocales();
    canAccessCompanies();
  });
</script>

<div
  class="h-screen w-screen flex flex-col items-center justify-center select-none overflow-hidden"
>
  <div
    class="absolute w-[80%] h-[90%] rounded-xl overflow-hidden flex flex-row-reverse min-w-[80%] min-h-[90%]"
    in:scale={{ duration: 1000, easing: quintOut }}
    out:scale={{ duration: 1000, easing: quintOut }}
  >
    {#if $showOverview}
      <OverviewPage />
    {:else if $showHistory}
      <HistoryPage />
    {:else if $showWithdraw}
      <WithdrawPage />
    {:else if $showDeposit}
      <DepositPage />
    {:else if $showStats}
      <StatsPage />
    {:else if $showCreditCard}
      <CreditCardPage />
    {:else if $showCompanies}
      <Companies />
    {/if}
    <!-- SideBar -->
    <div class="relative bg-gray-700/90 left-0 border border-gray-600/40 h-full w-40 flex flex-col items-center rounded-l-xl overflow-hidden">
      <div class="flex flex-col relative h-full w-full">
        <div class="flex flex-col w-full h-fit-content items-center items-center justify-between">
          <label class="text-white font-bold p-0 rounded flex flex-col items-center uppercase w-[100%]">
            <input
              type="radio"
              name="radio"
              value="overview"
              class="hidden peer"
              checked={$showOverview}
              on:change={() => {
                showOverview.set(true);
                showHistory.set(false);
                showWithdraw.set(false);
                showDeposit.set(false);
                showStats.set(false);
                showCreditCard.set(false);
                showCompanies.set(false);
              }}
            />
            <span
              class="w-[100%] relative flex flex-col items-center text-gray-300 py-4 transition-all duration-500 rounded-xl
              peer-checked:text-blue-400 peer-checked:shadow-lg hover:text-blue-300 duration-500 peer-checked:bg-gray-800/60 hover:cursor-pointer hover:bg-gray-800/80"
            >
              <i class="fa-duotone fa-house text-3xl text-blue-300 mb-2"></i>
              <span class="relative">{$Locales.overview}</span>
            </span>
          </label>

          <label class="text-white font-bold p-0 rounded flex flex-col items-center uppercase w-[100%]">
            <input
              type="radio"
              name="radio"
              value="history"
              class="hidden peer"
              checked={$showHistory}
              on:change={() => {
                showOverview.set(false);
                showHistory.set(true);
                showWithdraw.set(false);
                showDeposit.set(false);
                showStats.set(false);
                showCreditCard.set(false);
                showCompanies.set(false);
              }}
            />
            <span
              class="w-[100%] relative flex flex-col items-center text-gray-300 py-4 transition-all duration-500 rounded-xl
              peer-checked:text-blue-400 peer-checked:shadow-lg hover:text-blue-300 duration-500 peer-checked:bg-gray-800/60 hover:cursor-pointer hover:bg-gray-800/80"
            >
              <i class="fa-duotone fa-circle-dollar text-3xl text-blue-300 mb-2"></i>
              <span class="relative">{$Locales.history}</span>
            </span>
          </label>

          <label class="text-white font-bold p-0 rounded flex flex-col items-center uppercase w-[100%]">
            <input
              type="radio"
              name="radio"
              value="control"
              class="hidden peer"
              checked={$showWithdraw}
              on:change={() => {
                showOverview.set(false);
                showHistory.set(false);
                showWithdraw.set(true);
                showDeposit.set(false);
                showStats.set(false);
                showCreditCard.set(false);
                showCompanies.set(false);
              }}
            />
            <span
              class="w-[100%] relative flex flex-col items-center text-gray-300 py-4 transition-all duration-500 rounded-xl
              peer-checked:text-blue-400 peer-checked:shadow-lg hover:text-blue-300 duration-500 peer-checked:bg-gray-800/60 hover:cursor-pointer hover:bg-gray-800/80"
            >
              <i class="fa-duotone fa-minus text-3xl text-blue-300 mb-2"></i>
              <span class="relative">{$Locales.withdraw}</span>
            </span>
          </label>

          <label class="text-white font-bold p-0 rounded flex flex-col items-center uppercase w-[100%]">
            <input
              type="radio"
              name="radio"
              value="control"
              class="hidden peer"
              checked={$showDeposit}
              on:change={() => {
                showOverview.set(false);
                showHistory.set(false);
                showWithdraw.set(false);
                showDeposit.set(true);
                showStats.set(false);
                showCreditCard.set(false);
                showCompanies.set(false);
              }}
            />
            <span
              class="w-[100%] relative flex flex-col items-center text-gray-300 py-4 transition-all duration-500 rounded-xl
              peer-checked:text-blue-400 peer-checked:shadow-lg hover:text-blue-300 duration-500 peer-checked:bg-gray-800/60 hover:cursor-pointer hover:bg-gray-800/80"
            >
              <i class="fa-duotone fa-plus text-3xl text-blue-300 mb-2"></i>
              <span class="relative">{$Locales.deposit}</span>
            </span>
          </label>

          <label class="text-white font-bold p-0 rounded flex flex-col items-center uppercase w-[100%]">
            <input
              type="radio"
              name="radio"
              value="control"
              class="hidden peer"
              checked={$showStats}
              on:change={() => {
                showOverview.set(false);
                showHistory.set(false);
                showWithdraw.set(false);
                showDeposit.set(false);
                showStats.set(true);
                showCreditCard.set(false);
                showCompanies.set(false);
              }}
            />
            <span
              class="w-[100%] relative flex flex-col items-center text-gray-300 py-4 transition-all duration-500 rounded-xl
              peer-checked:text-blue-400 peer-checked:shadow-lg hover:text-blue-300 duration-500 peer-checked:bg-gray-800/60 hover:cursor-pointer hover:bg-gray-800/80"
            >
              <i class="fa-duotone fa-chart-simple text-3xl text-blue-300 mb-2"></i>
              <span class="relative">{$Locales.stats}</span>
            </span>
          </label>

          <label class="text-white font-bold p-0 rounded flex flex-col items-center uppercase w-[100%]">
            <input
              type="radio"
              name="radio"
              value="control"
              class="hidden peer"
              checked={$showCreditCard}
              on:change={() => {
                showOverview.set(false);
                showHistory.set(false);
                showWithdraw.set(false);
                showDeposit.set(false);
                showStats.set(false);
                showCreditCard.set(true);
                showCompanies.set(false);
              }}
            />
            <span
              class="w-[100%] relative flex flex-col items-center text-gray-300 py-4 transition-all duration-500 rounded-xl
              peer-checked:text-blue-400 peer-checked:shadow-lg hover:text-blue-300 duration-500 peer-checked:bg-gray-800/60 hover:cursor-pointer hover:bg-gray-800/80"
            >
              <i class="fa-duotone fa-credit-card text-3xl text-blue-300 mb-2"></i>
              <span class="relative">{$Locales.credit_card}</span>
            </span>
          </label>

          {#if $canShowCompanies}
          <label class="text-white font-bold p-0 rounded flex flex-col items-center uppercase w-[100%]">
            <input
              type="radio"
              name="radio"
              value="control"
              class="hidden peer"
              checked={$showCompanies}
              on:change={() => {
                showOverview.set(false);
                showHistory.set(false);
                showWithdraw.set(false);
                showDeposit.set(false);
                showStats.set(false);
                showCreditCard.set(false);
                showCompanies.set(true);
              }}
            />
            <span
              class="w-[100%] relative flex flex-col items-center text-gray-300 py-4 transition-all duration-500 rounded-xl
              peer-checked:text-blue-400 peer-checked:shadow-lg hover:text-blue-300 duration-500 peer-checked:bg-gray-800/60 hover:cursor-pointer hover:bg-gray-800/80"
            >
              <i class="fa-duotone fa-building text-3xl text-blue-300 mb-2"></i>
              <span class="relative">{$Locales.companies}</span>
            </span>
          </label>
          {/if}
        </div>

        <!-- Close -->
        <div class="flex flex-col w-full h-full items-center items-center justify-end">
          <label class="text-white font-bold p-0 rounded flex flex-col items-center uppercase w-[100%]">
            <input
              type="radio"
              name="radio"
              value="overview"
              class="hidden peer"
              checked={!$visibility}
              on:change={() => {
                fetchNui("fd_banking:client:hideUI");
                visibility.set(false);
              }}
            />
            <span
              class="w-[100%] relative flex flex-col items-center text-red-300 py-4 peer-checked:shadow-md transition-all duration-500 rounded-xl
              peer-checked:text-blue-400 peer-checked:shadow-lg hover:text-red-300 duration-500 peer-checked:bg-gray-600 hover:cursor-pointer hover:bg-red-800/80"
            >
              <i class="fa-duotone fa-circle-xmark text-3xl text-red-300 mb-2"></i>
              <span class="relative">{$Locales.close}</span>
            </span>
          </label>
        </div>
      </div>
    </div>
  </div>
</div>
