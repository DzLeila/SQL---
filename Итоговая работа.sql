--Задача 1 
--В каких городах больше одного аэропорта?
select city from airports -- получаю название городов из таблицы aiprorts
group by city -- группирую данную таблицу по полю city
having count(*) > 1 -- фильтрую по условию having, где кол-во сгруппированных записей должно быть больше 1

--Задача 2
--В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета? (обязательно: подзапрос)
select departure_airport as аэропорт --вывожу аэропорты из табл flights
from flights 
where aircraft_code =
(select aircraft_code -- в подзапросе вывожу самолет с максимальной дальностью   
from aircrafts_data 
order by "range"desc -- сортирую по убыванию
limit 1) -- и оставляю самый дальний
group by departure_airport -- группирую по названию аэропорта вылета

--Задача 3
--Вывести 10 рейсов с максимальным временем задержки вылета. Обязательно: limit
select flight_id , actual_departure - scheduled_departure as "время задержки"
from flights -- вывожу из табл flight данные по id и разность между фактическим временем вылета и временем вылета по расписанию
where actual_departure is not null -- исключаю записи, где фактическое время вылета null
order by "время задержки" desc -- сортирую полученную разность по убыванию
limit 10 -- вывожу первые 10 значений

--Задача 4
--Были ли брони, по которым не были получены посадочные талоны? Обязательно: верный тип join 
select count (*) as "кол-во броней без посадочного" -- считаю кол-во записей из табл bookings
from bookings
left join tickets on tickets.book_ref=bookings.book_ref -- присоединяю номера бронирования
left join boarding_passes on boarding_passes.ticket_no = tickets.ticket_no -- присоединяю номера билетов
where boarding_no is null -- фильтрую бронирования по тем значениям, где нет номеров посадочных талонов

--Задача 5
--Найдите количество свободных мест для каждого рейса, их % отношение к общему количеству мест в самолете.
--Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день. 
--Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах в течении дня.
--Обязательно: оконная функция, подзапросы или/и cte

--использую три таблицы: boarding_passes, flights, seats. Чтобы найти кол-во свободных мест, 
--нужно найти кол-во посадочных мест и кол-во выданных посадочных талонов.
with cte1 as -- в этом cte считаю кол-во посадочных мест для каждой модели
(select seats.aircraft_code , count(seats.seat_no) as "общее кол-во мест"
from seats
group by seats.aircraft_code),
cte2 as -- в этом cte обогащаю 1-е данными из табл flights и boarding_passes, чтобы найти выданные посадочные талоны 
(select flights.flight_id , flights.departure_airport , flights.actual_departure ,
cte1."общее кол-во мест",
count(boarding_passes.seat_no) as "места заняты", --кол-во мест занятых пассажирами
cte1."общее кол-во мест" - count(boarding_passes.seat_no) as "свободные места" , 
--кол-во свободных мест, считаю разность между общем кол-вом мест и выданными талонами
round((cte1."общее кол-во мест" - count(boarding_passes.seat_no))::numeric / cte1."общее кол-во мест" * 100) as "% свободных мест"
 --высчитываю процент свободных мест
from cte1
join flights on cte1.aircraft_code = flights.aircraft_code 
join boarding_passes on flights.flight_id = boarding_passes.flight_id 
group by flights.flight_id , cte1.aircraft_code, cte1."общее кол-во мест")
--соединяю таблицы и делаю группировку
select * , 
sum(cte2."места заняты") over (partition by cte2.actual_departure::date, 
cte2.departure_airport  order by cte2.actual_departure) as "суммарное накопление"
--созданную оконную фун-ю для расчёта суммарного накопления на каждый день из каждого аэропорта на каждый день
--суммирую кол-во занятых мест на рейсе, группирую по departure_airport, actual_departure
--привожу к типу данных date, чтобы убрать время и оставить возможность подсчета по дням
--сортирую по actual_departure где весть дата с указанием времени
from cte2
--Задача 6
--Найдите процентное соотношение перелетов по типам самолетов от общего количества. Обязательно: подзапрос или окно, оператор ROUND.
select aircrafts_data.model, -- получаю название моделей самолетов
round(count(*)::numeric  -- считаю кол-во рейсов(привожу к типу numeric для оторбражения остатка от деления) 
/ (select count(*) from flights) * 100, 1)
--и делю на подзапрос, где считаю общее кол-во рейсов, умножаю на 100, чтобы получить % (округляю до десятых)
as "процентное соотношение перелетов" -- именую колонку
from flights
inner join aircrafts_data on flights.aircraft_code = aircrafts_data.aircraft_code -- при помощи джойна из таблицы aircrafts_data подтягию моделю
group by aircrafts_data.aircraft_code -- группирую по коду судна

--Задача 7
--Были ли города, в которые можно добраться бизнес-классом дешевле, чем эконом-классом в рамках перелета? Обязательно: CTE.
--ответ: нет, не было
with cte_business as ( -- создаю cte для бизнес-класса
select flight_id, fare_conditions, min (amount) as "минимальная сумма" -- вывожу id рейса, класс обслуживания и считаю минимальную стоимость перелета
from ticket_flights
where fare_conditions = 'Business'
group by flight_id, fare_conditions), -- группирую
cte_economy as ( -- создаю cte для эконом-класса
select flight_id, fare_conditions, max(amount) as "максимальная сумма" ---- вывожу id рейса, класс обслуживания и считаю максимальную стоимость перелета
from ticket_flights
where fare_conditions = 'Economy' 
group by flight_id, fare_conditions) -- группирую
select flights.flight_id, city,"минимальная сумма", "максимальная сумма"  --вывожу еще города из airports_data
from airports_data
join flights on airports_data.airport_code = flights.arrival_airport -- добавляем аэропорты назначения в таблице flights названиями городов
join cte_business using (flight_id) -- присоединяю по id рейса из cte бизнес
join cte_economy using (flight_id) -- присоединяю по id рейса из cte эконом
where "минимальная сумма" < "максимальная сумма" -- добавляю условие по сумме, где минимальная стоимость бизнес должна быть меньше максимальной стоимости эконом

--Задача 8
--Между какими городами нет прямых рейсов? Обязательно: декартово произведение в предложении FROM, 
--самостоятельно созданные представления (если облачное подключение, то без представления),оператор EXCEPT.
select distinct t1.city, t2.city
from airports t1 -- создаем декартово произведение
cross join airports t2 --  использую кросс джойн для получение всех возможных пар городов с ней самой
where t1.city <> t2.city -- использую условие, которые уберет зеркальные города
except  -- удаляю из декартового произведения пары городв, которые есть в предствалении 
select departure_city, arrival_city
from routes r 

--Задача 9
--Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной дальностью перелетов  
--в самолетах, обслуживающих эти рейсы * Обязательно: оператор RADIANS или использование sind/cosd,CASE. 
select distinct --убираю дубли
t1.airport_name as "аэропорт отправления",
t2.airport_name as "аэропорт прилета",
a.model as "модель самолета",
a."range",
round((acos(sind(t1.coordinates [1]) * sind(t2.coordinates [1]) + cosd(t1.coordinates [1]) 
* cosd(t2.coordinates [1]) * cosd(t1.coordinates [0] - t2.coordinates [0])) * 6371)::numeric, 2) as "расстояние",	
-- осуществляю расчеты по формуле, с кординатами работаю через массив 0-широта, 1-долгота
case 
when a."range" < acos(sind(t1.coordinates [1]) * sind(t2.coordinates [1]) 
+ cosd(t1.coordinates [1]) * cosd(t2.coordinates [1]) * cosd(t1.coordinates [0] - t2.coordinates [0])) * 6371 
then 'нет'
else 'да'
end result 
--сравниваю с данными по расстоянию для модели самолета, если дальность меньше дальности полета, то "да"
from flights f
join airports t1 on f.departure_airport = t1.airport_code
join airports t2 on f.arrival_airport = t2.airport_code
join aircrafts a on a.aircraft_code = f.aircraft_code 
order by t1.airport_name, t2.airport_name, a.model 
-- объединяю данные, затем делаю сортировку



