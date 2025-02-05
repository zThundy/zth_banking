<script lang="ts">
  import { writable } from "svelte/store";
  import { onMount } from "svelte";
  import Chart from "chart.js/auto";
  import { fetchNui } from "../utils/fetchNui";
  import { quintOut } from "svelte/easing";
  import { slide } from "svelte/transition";
  import {
    showOverview,
    showHistory,
    showCreditCard,
    Transactions,
    currentCash,
    bankBalance,
    bankBalanceMex,
    Locales,
    type Notification,
  } from "../store/data";
  import { updateBalances } from "../store/methods";

  let weeklyData = writable({ totalReceived: 0, totalUsed: 0, });

  let chart: Chart;
  let chartCanvas: HTMLCanvasElement;

  async function fetchWeeklySummary() {
    fetchNui("fd_banking:client:getWeeklySummary", {})
      .then((response) => {
        if (response) {
          weeklyData.set(response);
        }
      })
      .catch((error) => {
        console.error(error);
      });
  }

  async function getHistory() {
    fetchNui("fd_banking:client:getHistory", {})
      .then(history => {
        Transactions.set(history);
      })
      .catch(error => {
        console.error(error);
      });
  }

  $: bankData = {
    balance: $bankBalance,
    balanceMex: $bankBalanceMex,
    cash: $currentCash,
    transactions: $Transactions,
  };

  function createChart() {
    if (chartCanvas) {
      chart = new Chart(chartCanvas, {
        type: "bar",
        data: {
          labels: [$Locales.income, $Locales.expenses],
          datasets: [
            {
              label: $Locales.weekly_summary,
              data: [0, 0],
              backgroundColor: ["#3b82f6", "#ef4444"],
            },
          ],
        },
        options: {
          responsive: true,
          scales: {
            y: {
              beginAtZero: true,
            },
          },
        },
      });
    }
  }

  $: {
    weeklyData.subscribe((data) => {
      if (chart) {
        chart.data.datasets[0].data = [data.totalReceived, data.totalUsed];
        chart.update();
      }
    });
  }

  async function updateStuff() {
    // Hot update
    await getHistory();
    await fetchWeeklySummary();
    await updateBalances();
  }

  onMount(async () => {
    createChart();
    updateStuff();
    updateStuff();
  });
</script>

<div class="relative bg-gray-800 w-full h-full">
  <div
    class="relative top-0 overflow-hidden p-6 text-white w-full h-full"
    in:slide={{ duration: 1000, easing: quintOut }}
  >
    <!-- Quick Actions -->
    <div class="mb-8">
      <div class="text-xl mb-4 text-blue-200">{$Locales.total_balance}</div>
      <div class="text-3xl font-bold mb-8 text-blue-300">
        USD {Math.ceil($bankBalance)}
        / MXN {Math.ceil($bankBalanceMex)}
      </div>
    </div>

    <div>
      <div class="text-2xl mb-4 text-blue-200">{$Locales.quick_actions}</div>
      
      <div class="flex w-full">
        <div class="items-center bg-gray-700 rounded-xl p-4 w-[50%] m-2 grid-cols-8 grid">
          <div class="flex col-span-2 items-center justify-center">
            <i class="fa-duotone fa-credit-card text-8xl text-blue-400"></i>
          </div>

          <div class="col-span-6 flex flex-col justify-right">
            <div class="text-2xl font-bold text-blue-200 text-right">
              {$Locales.credit_card}
            </div>
            <div class="text-sm mb-2 text-gray-400 text-right">
              {$Locales.credit_card_description}
            </div>
            <button
              class="bg-blue-600/10 border border-blue-500 hover:bg-blue-800/50 text-white font-bold py-2 px-4 mt-4 duration-500 rounded-lg cursor-pointer disabled:opacity-50 hover:cursor-pointer w-[50%] ml-auto"
              on:click={() => {
                showOverview.set(false);
                showCreditCard.set(true);
              }}
            >
              {$Locales.open}
            </button>
          </div>
        </div>

        <div class="items-center bg-gray-700 rounded-xl p-4 w-[50%] m-2 grid-cols-8 grid">
          <div class="flex col-span-2 items-center justify-center">
            <i class="fa-duotone fa-question text-8xl text-blue-400"></i>
          </div>

          <div class="col-span-6 flex flex-col justify-right">
            <div class="text-2xl font-bold text-blue-200 text-right">
              Coming soon...
            </div>
            <div class="text-sm mb-2 text-gray-400 text-right">
              This functionality is not available yet.
            </div>
            <button
              class="bg-blue-600/10 border border-blue-500 hover:bg-blue-800/50 text-white font-bold py-2 px-4 mt-4 duration-500 rounded-lg cursor-pointer disabled:opacity-50 hover:cursor-not-allowed w-[50%] ml-auto"
            >
              Coming soon...
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Lower Section -->
    <div class="flex w-full">
      <!-- Weekly Summary -->
      <div class="bg-gray-700 space-x-4 rounded-xl p-4 w-[50%] m-2">
        <div class="flex items-center mb-4">
          <i class="fa-duotone fa-calendar-week text-2xl text-blue-400 mr-2"></i>
          <span class="text-blue-200 font-bold text-xl">{$Locales.weekly_summary}</span>
        </div>
        <div class="space-y-4 border border-dashed border-blue-400 rounded-lg p-4">
          <div class="flex justify-between border-b border-gray-600 pb-2">
            <span>{$Locales.income}</span>
            <span class="text-blue-400">
              {#if $weeklyData.totalReceived !== undefined}
                {$weeklyData.totalReceived}
              {:else}
                0
              {/if}
            </span>
          </div>
          <div class="flex justify-between border-b border-gray-600 pb-2">
            <span>{$Locales.expenses}</span>
            <span class="text-red-400">
              {#if $weeklyData.totalUsed !== undefined}
                {$weeklyData.totalUsed}
              {:else}
                0
              {/if}
            </span>
          </div>
          <div class="mt-6">
            <div class="flex items-center mb-2">
              <i class="fa-duotone fa-chart-bar text-xl text-blue-400 mr-2"></i>
              <span>{$Locales.report}</span>
            </div>
            <div>
              <canvas bind:this={chartCanvas}></canvas>
            </div>
          </div>
        </div>
      </div>

      <!-- Latest Transactions -->
      <div class="flex flex-col bg-gray-700 space-x-4 rounded-xl p-4 w-[50%] m-2">
        <div class="flex justify-between items-center mb-4">
          <div class="flex items-center">
            <i class="fa-duotone fa-file-invoice text-2xl text-blue-400 mr-2"></i>
            <span class="text-blue-200 font-bold text-xl">
              {$Locales.latest_transactions}
            </span>
          </div>
          <div class="bg-gray-600 rounded-full px-2 py-1">
            <span class="text-white text-sm">
              {bankData.transactions.length}
            </span>
          </div>
        </div>
        
        <div class="space-y-3 border border-dashed border-blue-400 rounded-lg p-4 h-[100%] overflow-auto flex flex-col flex-nowrap align-center jusify-start max-h-[25rem]">
          {#if bankData.transactions.length > 0}
            {#each bankData.transactions as transaction}
              <div class="space-y-2">
                <div class="flex justify-between">
                  <span class="truncate">{transaction.description}</span>
                  <p class={`text-md font-bold ${transaction.isIncome ? "text-green-500" : "text-red-500"}`}>
                    {transaction.isIncome ? "+" : "-"}
                    {transaction.amount}
                  </p>
                </div>
                <div class="border-b border-gray-600"></div>
              </div>
            {/each}
          {:else}
            <div class="p-4 text-center text-blue-200">
              <i class="fa-duotone fa-check-circle text-2xl mb-2"></i>
              <p>{$Locales.no_transactions}</p>
            </div>
          {/if}
        </div>

        <div class="flex justify-center">
          <button
            class="bg-blue-600/10 border border-blue-500 hover:bg-blue-800/50 text-white font-bold py-2 px-4 mt-4 duration-500 rounded-lg cursor-pointer"
            on:click={() => {
              showOverview.set(false);
              showHistory.set(true);
            }}
          >
            {$Locales.see_all}
          </button>
        </div>
      </div>
    </div>
  </div>
</div>
