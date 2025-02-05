<script lang="ts">
  import { writable, get } from "svelte/store";
  import { onMount } from "svelte";
  import { fetchNui } from "../utils/fetchNui";
  import { slide, fade, scale } from "svelte/transition";
  import { quintOut } from "svelte/easing";
  import {
    showATM,
    currentCash,
    bankBalance,
    bankBalanceMex,
    Notify,
    Locales,
    atmCurrency,
    currentMexCash,
  } from "../store/data";
  import { updateBalances, floorToTwoDecimals, getLocales } from "../store/methods";

  let customDeposit = writable(0);
  let customWithdraw = writable(0);
  if ($atmCurrency === "USD") {
    customWithdraw = writable(floorToTwoDecimals($bankBalance));
    customDeposit = writable(floorToTwoDecimals($currentCash));
  } else {
    customWithdraw = writable(floorToTwoDecimals($bankBalanceMex));
    customDeposit = writable(floorToTwoDecimals($currentMexCash));
  }

  async function withdraw(amount: number) {
    fetchNui("fd_banking:client:ATMwithdraw", {
      amount: amount,
      type: $atmCurrency,
    })
      .then((response) => {
        if (response) {
          Notify(`${$Locales.withdrawn} ${$atmCurrency} ${amount}`, $Locales.payment_completed, "coins");
          updateBalances();
        } else {
          Notify($Locales.no_money_on_account, $Locales.error, "credit-card");
        }
      })
      .catch((error) => {
        console.error(error);
      });
  }

  async function deposit(amount: number) {
    fetchNui("fd_banking:client:ATMdeposit", {
      amount: amount,
      type: $atmCurrency,
    })
      .then((response) => {
        if (response) {
          Notify(`${$Locales.deposited} ${$atmCurrency} ${amount}`, $Locales.payment_completed, "coins");
          updateBalances();
        } else {
          Notify($Locales.no_cash_on_you, $Locales.error, "credit-card");
        }
      })
      .catch((error) => {
        console.error(error);
      });
  }

  onMount(() => {
    getLocales();
    updateBalances();
    const keyHandler = (e: KeyboardEvent) => {
      if (get(showATM) && ["Escape"].includes(e.code)) {
        fetchNui("fd_banking:client:hideUI");
        showATM.set(false);
      }
    };
    window.addEventListener("keydown", keyHandler);
    return () => window.removeEventListener("keydown", keyHandler);
  });
</script>

<div class="absolute w-screen h-screen flex items-center justify-center">
  <div
    class="absolute inset-0 flex items-center justify-center"
    in:scale={{ duration: 1000, easing: quintOut }}
    out:scale={{ duration: 1000, easing: quintOut }}
  >
    <div
      class="h-auto w-[60%] bg-gray-800 rounded-3xl p-8 shadow-2xl relative border border-blue-200/10"
    >
      <div class="text-4xl font-bold text-center text-blue-200 mb-6">
        <i class="fa-duotone fa-atm text-blue-200 mr-2"></i>{$Locales.atm}
      </div>
      <div class="grid grid-cols-2 gap-6 mb-8">
        <div
          class="bg-gray-700 p-6 rounded-2xl shadow-lg flex flex-col items-center justify-center"
        >
          <div class="text-2xl font-semibold text-blue-100 mb-2">
            <i class="fa-duotone fa-money-bill-wave text-md mr-2"></i>
            {$Locales.cash}
          </div>
          <div class="text-4xl font-bold text-blue-400">
            {#if $atmCurrency === "USD"}
              USD {floorToTwoDecimals($currentCash)}
            {:else}
              MXN {floorToTwoDecimals($currentMexCash)}
            {/if}
          </div>
        </div>
        <div
          class="bg-gray-700 p-6 rounded-2xl shadow-lg flex flex-col items-center justify-center"
        >
          <div class="text-2xl font-semibold text-blue-100 mb-2">
            <i class="fa-duotone fa-vault text-md mr-2"
            ></i>{$Locales.bank_balance}
          </div>
          <div class="text-4xl font-bold text-blue-400">
            {#if $atmCurrency === "USD"}
              USD {floorToTwoDecimals($bankBalance)}
            {:else}
              MXN {floorToTwoDecimals($bankBalanceMex)}
            {/if}
          </div>
        </div>
      </div>

      <div class="grid grid-cols-2 gap-4 mt-4">
        <div class="bg-gray-700 p-4 rounded-xl shadow-lg">
          <div class="flex items-center mb-2">
            <i
              class="fa-duotone fa-money-check-edit text-xl text-green-400 mr-2"
            ></i>
            <label for="Deposit" class="text-lg font-semibold text-white">
              {$Locales.deposit_amount}
            </label>
          </div>
          <input
            type="number"
            id="Deposit"
            bind:value={$customDeposit}
            class="w-full bg-gray-800 text-white font-bold pl-4 pr-4 py-3 rounded-lg border border-green-200/10 focus:outline-none focus:border-green-400/50 transition-colors duration-500 placeholder-gray-500"
            placeholder={$Locales.deposit_amount}
          />
          <button
            class="mt-2 w-full bg-green-600/10 border border-green-500 hover:bg-green-800/50 text-white font-bold py-2 px-4 rounded-xl duration-500 cursor-pointer flex items-center justify-center gap-2"
            on:click={() => {
              deposit(get(customDeposit));
            }}
          >
            <i class="fa-duotone fa-piggy-bank text-lg"></i>
            {$Locales.submit}
          </button>
        </div>
        <div class="bg-gray-700 p-4 rounded-xl shadow-lg">
          <div class="flex items-center mb-2">
            <i class="fa-duotone fa-money-check-edit text-xl text-blue-400 mr-2"
            ></i>
            <label for="Withdraw" class="text-lg font-semibold text-white">
              {$Locales.withdraw_amount}
            </label>
          </div>
          <input
            type="number"
            id="Withdraw"
            bind:value={$customWithdraw}
            class="w-full bg-gray-800 font-bold text-white pl-4 pr-4 py-3 rounded-lg border border-blue-200/10 focus:outline-none focus:border-blue-400/50 transition-colors duration-500 placeholder-gray-500"
            placeholder={$Locales.withdraw_amount}
          />
          <button
            class="mt-2 w-full bg-blue-600/10 border border-blue-500 hover:bg-blue-800/50 text-white font-bold py-2 px-4 rounded-xl duration-500 cursor-pointer flex items-center justify-center gap-2"
            on:click={() => {
              withdraw(get(customWithdraw));
            }}
          >
            <i class="fa-duotone fa-money-bill-wave text-lg"></i>
            {$Locales.submit}
          </button>
        </div>
      </div>
      <div class="absolute top-4 right-4 transform -translate-x-1/2 text-white">
        <button
          class="text-blue-200/50 hover:text-blue-500/50 font-bold py-2 px-4 rounded-xl duration-500 cursor-pointer flex items-center justify-center gap-2 text-gray-300 py-4 transition-all duration-500 rounded-xl hover:text-blue-300 duration-500 hover:cursor-pointer hover:bg-gray-800/80"
          on:click={() => {
            showATM.set(false);
            fetchNui("fd_banking:client:hideUI");
          }}
        >
          <i class="fa-duotone fa-times-circle text-2xl"></i>
        </button>
      </div>
    </div>
  </div>
</div>
