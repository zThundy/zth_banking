<script lang="ts">
  import { writable } from "svelte/store";
  import { slide, scale } from "svelte/transition";
  import { quintOut } from "svelte/easing";
  import { onMount } from "svelte";
  import {
    Notify,
    currentCash,
    bankBalance,
    Locales,
  } from "../store/data";
  import { fetchNui } from "../utils/fetchNui";
  import {
    Chart,
    LineController,
    LineElement,
    PointElement,
    LinearScale,
    Title,
    CategoryScale,
    Tooltip,
  } from "chart.js";

  let totalTransactions = writable(0);
  let totalAmount = writable(0);

  let dataSheets = {
    TransactionsPositive: [] as number[],
    TransactionsNegative: [] as number[],
    Dates: [] as string[],
    Min: 0,
    Max: 0,
  };

  let chart: Chart<"line", number[], string>;

  async function fetchTransactionStats() {
    try {
      const stats = await fetchNui("fd_banking:client:getTransactionStats", {});
      totalTransactions.set(stats.totalCount);
      totalAmount.set(stats.totalAmount);

      const transactionDataPositive = stats.transactionData.positive.map(
        (stat: { amount: any, id: any, date: any }) => ({ amount: stat.amount, id: stat.id, date: new Date(stat.date).toLocaleDateString() })
      );
      const transactionDataNegative = stats.transactionData.negative.map(
        (stat: { amount: any, id: any, date: any }) => ({ amount: stat.amount, id: stat.id, date: new Date(stat.date).toLocaleDateString() })
      );
      
      let Transactions = [...transactionDataPositive, ...transactionDataNegative] as any;
      // sort for Transactions.id
      Transactions.sort((a: { id: number }, b: { id: number }) => a.id - b.id);
      // map ids from the
      const TransactionsIds = Transactions.map((transaction: { id: string }) => transaction.id);
      for (let i = 0; i < TransactionsIds.length; i++) {
        dataSheets.Dates.push(Transactions[i].date);
      }

      dataSheets.Min = Math.min(
        ...transactionDataPositive.map(
          (transaction: { amount: string }) => transaction.amount
        ),
        ...transactionDataNegative.map(
          (transaction: { amount: string }) => transaction.amount
        )
      );

      dataSheets.Max = Math.max(
        ...transactionDataPositive.map(
          (transaction: { amount: string }) => transaction.amount
        ),
        ...transactionDataNegative.map(
          (transaction: { amount: string }) => transaction.amount
        )
      );

      dataSheets.TransactionsPositive = Transactions.map(
        (transaction: { amount: number }) => transaction.amount > 0 ? transaction.amount : 0
      );
      dataSheets.TransactionsNegative = Transactions.map(
        (transaction: { amount: number }) => transaction.amount < 0 ? transaction.amount : 0
      );

      if (chart) {
        chart.data.labels = dataSheets.Dates;
        chart.data.datasets[0].data = dataSheets.TransactionsPositive;
        chart.data.datasets[1].data = dataSheets.TransactionsNegative;
        chart.update();
      }
    } catch (error) {
      console.error("Error fetching transaction stats:", error);
    }
  }

  Chart.register(
    LineController,
    LineElement,
    PointElement,
    LinearScale,
    Title,
    CategoryScale,
    Tooltip
  );

  onMount(() => {
    fetchTransactionStats();

    // @ts-expect-error
    const ctx = document.getElementById("transactionChart").getContext("2d");
    chart = new Chart(ctx, {
      type: "line",
      data: {
        labels: dataSheets.Dates,
        datasets: [
          {
            label: $Locales.stats_history_positive,
            data: dataSheets.TransactionsPositive,
            borderColor: "rgba(59, 130, 246, 1)",
            backgroundColor: "rgba(59, 130, 246, 0.2)",
            fill: true,
            tension: 0.5,
            pointStyle: "rectRounded",
            pointRadius: 10,
            pointHoverRadius: 15,
            borderWidth: 2,
          },
          {
            label: $Locales.stats_history_negative,
            data: dataSheets.TransactionsNegative,
            borderColor: "rgba(246, 59, 59, 1)",
            backgroundColor: "rgba(246, 59, 59, 0.2)",
            fill: true,
            tension: 0.5,
            pointStyle: "rectRounded",
            pointRadius: 10,
            pointHoverRadius: 15,
            borderWidth: 2,
          },
        ],
      },
      options: {
        responsive: true,
        plugins: {
          legend: {
            display: true,
            position: "top",
            labels: {
              usePointStyle: true,
              color: "white",
            },
          },
          tooltip: {
            backgroundColor: "rgba(0,0,0,0.7)",
            titleColor: "white",
            bodyColor: "white",
            cornerRadius: 4,
            displayColors: false,
          },
        },
        scales: {
          x: {
            display: true,
            title: {
              display: true,
              text: $Locales.date,
              color: "white",
            },
            ticks: {
              color: "white",
            },
            grid: {
              color: "rgba(255,255,255,0.1)",
            },
          },
          y: {
            display: true,
            title: {
              display: true,
              text: $Locales.amount,
              color: "white",
            },
            ticks: {
              color: "white",
            },
            grid: {
              color: "rgba(255,255,255,0.1)",
            },
            suggestedMin: dataSheets.Min,
            suggestedMax: dataSheets.Max,
          },
        },
      },
    });
  });
</script>

<!-- svelte-ignore a11y-label-has-associated-control -->
<div class="relative bg-gray-800 w-full h-full">
  <div
    class="relative top-0 overflow-hidden p-6 text-white w-full h-full"
    in:slide={{ duration: 1000, easing: quintOut }}
  >
    <div class="bg-gray-700/20 rounded-lg shadow-md p-6 border border-blue-200/5 mb-6">
      <div class="flex items-center mb-6">
        <i class="fa-duotone fa-chart-simple text-3xl text-blue-400 mr-3"></i>
        <h2 class="text-3xl font-bold">{$Locales.statistics_reports}</h2>
      </div>
      <!-- <h2 class="text-3xl font-bold mb-6">{$Locales.statistics_reports}</h2> -->


      <div class="flex justify-between items-center mb-6">
        <div class="flex items-center">
          <i class="fa-duotone fa-chart-line text-3xl text-blue-200 mr-3"></i>
          <h3 class="text-2xl font-semibold text-blue-200">
            {$Locales.overview}
          </h3>
        </div>
        <div class="bg-gray-500/40 rounded-xl px-3 py-1 flex items-center">
          <i class="fa-duotone fa-wallet text-gray-400 mr-2"></i>
          <span class="text-lg font-semibold text-white">
            {$Locales.total_balance}: {#if $bankBalance !== undefined}
              {$bankBalance}
            {/if}
          </span>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
        <div class="bg-gray-700 p-4 rounded-lg shadow">
          <div class="flex justify-between items-center mb-4">
            <h4 class="text-xl font-semibold text-blue-200">
              {$Locales.total_transactions}
            </h4>
            <i class="fa-duotone fa-exchange-alt text-yellow-400 text-2xl"></i>
          </div>
          <p class="text-2xl font-bold">{$totalTransactions}</p>
        </div>
        <div class="bg-gray-700 p-4 rounded-lg shadow">
          <div class="flex justify-between items-center mb-4">
            <h4 class="text-xl font-semibold text-blue-200">
              {$Locales.amount}
            </h4>
            <i class="fa-duotone fa-coins text-green-400 text-2xl"></i>
          </div>
          <p class="text-2xl font-bold">
            {#if $totalAmount !== undefined}
              {$totalAmount}
            {:else}
              0
            {/if}
          </p>
        </div>
      </div>
      
      <div class="bg-gray-700 p-4 rounded-lg shadow">
        <div class="flex justify-between items-center mb-4">
          <h4 class="text-xl font-semibold text-blue-200">
            {$Locales.transactions_trend}
          </h4>
          <i class="fa-duotone fa-chart-line text-blue-400 text-2xl"></i>
        </div>
        <div
          class="relative w-[90%] m-auto"
          in:scale={{ duration: 2500, easing: quintOut }}
        >
          <canvas id="transactionChart"></canvas>
        </div>
      </div>
    </div>
  </div>
</div>
