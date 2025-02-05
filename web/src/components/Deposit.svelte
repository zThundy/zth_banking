<script lang="ts">
  import { writable } from "svelte/store";
  import { slide } from "svelte/transition";
  import { quintOut } from "svelte/easing";
  import { fetchNui } from "../utils/fetchNui";
  import {
    Notify,
    currentCash,
    bankBalance,
    bankBalanceMex,
    conversionRate,
    currentMexCash,
    Locales,
  } from "../store/data";
  import { floorToTwoDecimals } from "../store/methods";


  let depositAmount = writable(0);
  let localAmount = writable($currentCash);
  let localType = writable("USD");
  // $: newCash = $currentCash - $depositAmount;
  // $: newCashMex = $currentMexCash - $depositAmount;
  $: newBank = $localType === "USD" ? $bankBalance + $depositAmount : $bankBalance + ($depositAmount / $conversionRate);
  $: computedString = $localType === "USD" ? "USD " + floorToTwoDecimals($currentCash - $depositAmount) : "MXN " + floorToTwoDecimals($currentMexCash - $depositAmount);

  async function handleDeposit() {
    let localCashAmount = $localType === "USD" ? $currentCash : $currentMexCash;

    if (localCashAmount < $depositAmount) {
      Notify(`${$Locales.deposit_error} ${$localType} ${$depositAmount}`, $Locales.withdraw_error, "coins");
    } else {
      Notify(`${$Locales.deposit_success} ${$localType} ${$depositAmount}`, $Locales.deposit_success, "coins");

      await fetchNui("fd_banking:client:ATMdeposit", {
        amount: $depositAmount,
        type: $localType,
      });

      if ($localType === "USD") {
        currentCash.update((cash) => cash - $depositAmount);
        bankBalance.update((balance) => balance + $depositAmount);
        bankBalanceMex.update((balance) => floorToTwoDecimals(balance + ($depositAmount * $conversionRate)));
        localAmount.set($currentCash);
      } else {
        currentMexCash.update((cash) => cash - $depositAmount);
        bankBalance.update((balance) => floorToTwoDecimals(balance + ($depositAmount / $conversionRate)));
        bankBalanceMex.update((balance) => balance + $depositAmount);
        localAmount.set($currentMexCash);
      }

      depositAmount.set(0);
    }
  }

  const currencySwitch = ({ target }: any) => {
    if (target && target.value === "USD") {
      localAmount.set($currentCash);
      localType.set("USD");
    } else {
      localAmount.set($currentMexCash);
      localType.set("MXN");
    }
  }
</script>

<!-- svelte-ignore a11y-label-has-associated-control -->
<div class="relative bg-gray-800 w-full h-full">
  <div
    class="relative top-0 overflow-hidden p-6 text-white w-full h-full"
    in:slide={{ duration: 1000, easing: quintOut }}
  >
    <div class="bg-gray-700/20 p-8 rounded-lg shadow-lg border border-blue-200/5">
      <div class="flex items-center mb-6">
        <i class="fa-duotone fa-plus text-3xl text-blue-400 mr-3"></i>
        <h2 class="text-3xl font-bold">{$Locales.deposit}</h2>
      </div>
      <!-- <h2 class="text-3xl font-bold mb-6">{$Locales.deposit}</h2> -->

      <div class="mb-12">
        <label class="block text-blue-200 mb-1">{$Locales.current_cash}</label>
        <div class="flex items-center text-2xl font-semibold">
          <i class="fa-duotone fa-wallet text-gray-400 mr-2"></i>
          {floorToTwoDecimals($localAmount)}
          <select
            class="bg-gray-700/50 text-white pl-2 pr-4 py-3 border border-blue-200/10 rounded-lg focus:outline-none
              focus:border-blue-400/50 transition-colors duration-500 ml-2"
              on:change={currencySwitch}
          >
            <option value={"USD"}>USD</option>
            <option value={"MXN"}>MXN</option>
          </select>
        </div>
      </div>

      <div class="mb-12">
        <label class="block text-blue-200 mb-1">{$Locales.amount}</label>
        <div class="relative">
          <i
            class="fa-duotone fa-money-bill-wave absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"
          ></i>
          <input
            type="number"
            class="w-full rounded bg-gray-700/50 text-white pl-10 pr-4 py-3 border border-blue-200/10 rounded-lg focus:outline-none
              focus:border-blue-400/50 transition-colors duration-500"
            bind:value={$depositAmount}
          />
        </div>
      </div>

      <div class="mb-12">
        <label class="block text-blue-200 mb-1">{$Locales.new_cash}</label>
        <div class="flex items-center text-2xl font-semibold">
          <i class="fa-duotone fa-coins text-gray-400 mr-2"></i>
          {computedString}
        </div>
      </div>

      <div class="mb-12">
        <label class="block text-blue-200 mb-1">{$Locales.new_bank}</label>
        <div class="flex items-center text-2xl font-semibold">
          <i class="fa-duotone fa-coins text-gray-400 mr-2"></i>
          USD {floorToTwoDecimals(newBank)}
        </div>
      </div>

      <button
        class="w-full bg-blue-600/10 hover:bg-blue-700/10 text-white font-bold py-3 rounded transition duration-300 flex items-center justify-center border border-blue-500/50"
        on:click={handleDeposit}
      >
        <i class="fa-duotone fa-money-check-edit text-lg mr-2"></i>
        {$Locales.deposit_button}
      </button>
    </div>
  </div>
</div>
