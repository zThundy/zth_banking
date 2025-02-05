<script lang="ts">
  import { writable } from "svelte/store";
  import { slide } from "svelte/transition";
  import { quintOut } from "svelte/easing";
  import { fetchNui } from "../utils/fetchNui";
  import {
    Notify,
    currentCash,
    currentMexCash,
    bankBalance,
    bankBalanceMex,
    conversionRate,
    Locales,
  } from "../store/data";
  import { floorToTwoDecimals } from "../store/methods";

  let withdrawAmount = writable(0);
  let localAmount = writable($bankBalance);
  let localType = writable("USD");
  // $: newBank = $bankBalance - $withdrawAmount;
  // $: newBankMex = ($bankBalance * $conversionRate) - $withdrawAmount;
  $: computedString = $localType === "USD" ? "USD " + floorToTwoDecimals($bankBalance - $withdrawAmount) : "MXN " + floorToTwoDecimals(($bankBalance * $conversionRate) - $withdrawAmount);

  async function handleWithdraw() {
    let localBankBalance = $localType === "USD" ? $bankBalance : ($bankBalance * $conversionRate);

    if (localBankBalance < $withdrawAmount) {
      Notify(`${$Locales.withdraw_error} ${$localType} ${$withdrawAmount}`, $Locales.withdraw_error, "coins");
    } else {
      Notify(`${$Locales.withdraw_success} ${$localType} ${$withdrawAmount}`, $Locales.withdraw_success, "coins");

      await fetchNui("fd_banking:client:ATMwithdraw", {
        amount: $withdrawAmount,
        type: $localType,
      });
      
      // currentCash.update((cash) => cash + $withdrawAmount);
      if ($localType === "USD") {
        currentCash.update((cash) => cash + $withdrawAmount);
        bankBalance.update((balance) => balance - $withdrawAmount);
        bankBalanceMex.update((balance) => floorToTwoDecimals(balance - ($withdrawAmount * $conversionRate)));
        localAmount.set($bankBalance);
      } else {
        currentMexCash.update((cash) => cash + $withdrawAmount);
        bankBalance.update((balance) => floorToTwoDecimals(balance - ($withdrawAmount / $conversionRate)));
        bankBalanceMex.update((balance) => balance - $withdrawAmount);
        localAmount.set($bankBalanceMex);
      }

      withdrawAmount.set(0);
    }
  }

  const currencySwitch = ({ target }: any) => {
    if (target && target.value === "USD") {
      localAmount.set($bankBalance);
      localType.set("USD");
    } else {
      localAmount.set($bankBalance * $conversionRate);
      localType.set("MXN");
    }
  }

  const withdrawAmountUpdate = ({ target }: any) => {
    if (target.value.length === 0) {
      withdrawAmount.set(0);
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
        <i class="fa-duotone fa-minus text-3xl text-blue-400 mr-3"></i>
        <h2 class="text-3xl font-bold">{$Locales.withdraw}</h2>
      </div>
      <!-- <h2 class="text-3xl font-bold mb-6">{$Locales.withdraw}</h2> -->

      <div class="mb-12">
        <label class="block text-blue-200 mb-1">{$Locales.bank_balance}</label>
        <div class="flex items-center text-2xl font-semibold">
          <i class="fa-duotone fa-university text-gray-400 mr-2"></i>
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
              bind:value={$withdrawAmount}
              on:change={withdrawAmountUpdate}
          />
        </div>
      </div>

      <div class="mb-12">
        <label class="block text-blue-200 mb-1">{$Locales.new_bank}</label>
        <div class="flex items-center text-2xl font-semibold">
          <i class="fa-duotone fa-coins text-gray-400 mr-2"></i>
          {computedString}
        </div>
      </div>

      <button
        class="w-full bg-blue-600/10 hover:bg-blue-700/10 text-white font-bold py-3 rounded transition duration-300 flex items-center justify-center border border-blue-500/50"
        on:click={handleWithdraw}
      >
        <i class="fa-duotone fa-money-check-edit text-lg mr-2"></i>
        {$Locales.withdraw_button}
      </button>
    </div>
  </div>
</div>
